import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../widgets/custom_elevated_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_export.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/report_download.dart';

class ReportsPage extends StatefulWidget {
  @override
  _ReportsPageState createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  TextEditingController fromDateController = TextEditingController();
  TextEditingController toDateController = TextEditingController();
  DateTime startDate = DateTime.now().subtract(Duration(days: 30));
  DateTime endDate = DateTime.now();
  bool isGenerating = false;

  @override
  void initState() {
    super.initState();
    fromDateController.text = DateFormat('yyyy-MM-dd').format(startDate);
    toDateController.text = DateFormat('yyyy-MM-dd').format(endDate);
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    DateTime initialDate = isStartDate ? startDate : endDate;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
          fromDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        } else {
          endDate = picked;
          toDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        }
      });
    }
  }

  Future<void> generateReport() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userDataString = prefs.getString('userData');

    if (userDataString == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User data is not available.")),
      );
      return;
    }

    final Map<String, dynamic> userData = json.decode(userDataString);
    final int? userId = userData['id'];
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User ID is not available.")),
      );
      return;
    }

    setState(() => isGenerating = true);

    try {
      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('generate_prescription_report')),
        body: {
          "from_date": fromDateController.text,
          "to_date": toDateController.text,
          "usr_id": userId.toString(),
        },
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData["success"] == true) {
        final downloadUrl = responseData["download_url"]?.toString() ?? '';
        final note = responseData["note"]?.toString() ??
            "Use your 8-digit report decryption code to open the PDF.";

        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Report Ready"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(responseData["message"]?.toString() ??
                    "Your encrypted report is ready."),
                SizedBox(height: 12),
                Text(note, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Close"),
              ),
              if (downloadUrl.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final error = await downloadAndOpenReportPdf(downloadUrl);
                    if (error != null && mounted) {
                      final opened = await openReportDownloadUrl(downloadUrl);
                      if (!opened && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error)),
                        );
                      }
                    }
                  },
                  child: Text("Download PDF"),
                ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ??
                "No data available for the selected date range."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error generating report: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Prescription Reports",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: theme.colorScheme.primary,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: fromDateController,
              decoration: InputDecoration(
                labelText: "From Date",
                suffixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              onTap: () => _selectDate(context, true),
            ),
            SizedBox(height: 16),
            TextField(
              controller: toDateController,
              decoration: InputDecoration(
                labelText: "To Date",
                suffixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              onTap: () => _selectDate(context, false),
            ),
            SizedBox(height: 16),
            Text(
              "Reports are generated on the server and encrypted with your 8-digit code sent to your email.",
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            SizedBox(height: 24),
            isGenerating
                ? Center(child: CircularProgressIndicator())
                : CustomElevatedButton(
                    text: "Generate Report",
                    onPressed: generateReport,
                  ),
          ],
        ),
      ),
    );
  }
}
