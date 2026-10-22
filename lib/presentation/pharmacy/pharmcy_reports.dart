import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../widgets/custom_elevated_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_export.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/report_download.dart';

class PReportsPage extends StatefulWidget {
  @override
  _ReportsPagePState createState() => _ReportsPagePState();
}

class _ReportsPagePState extends State<PReportsPage> {
  TextEditingController fromDateController = TextEditingController();
  TextEditingController toDateController = TextEditingController();
  DateTime startDate = DateTime.now().subtract(Duration(days: 30));
  DateTime endDate = DateTime.now();
  bool isGenerating = false;
  bool isLoadingPreview = false;
  List<Map<String, dynamic>> prescriptions = [];

  @override
  void initState() {
    super.initState();
    fromDateController.text = DateFormat('yyyy-MM-dd').format(startDate);
    toDateController.text = DateFormat('yyyy-MM-dd').format(endDate);
    fetchPrescriptions();
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
      fetchPrescriptions();
    }
  }

  Future<int?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('userData');
    if (userDataString == null) return null;
    final userData = json.decode(userDataString);
    return userData['id'];
  }

  Future<void> fetchPrescriptions() async {
    final userId = await _getUserId();
    if (userId == null) return;

    setState(() => isLoadingPreview = true);

    try {
      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('fetchpharmacy_Prescriptions')),
        body: {
          'from_date': fromDateController.text,
          'to_date': toDateController.text,
          'usr_id': userId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            prescriptions =
                List<Map<String, dynamic>>.from(data['data']);
          });
        } else {
          setState(() => prescriptions = []);
        }
      }
    } catch (_) {
      setState(() => prescriptions = []);
    } finally {
      if (mounted) setState(() => isLoadingPreview = false);
    }
  }

  String _orderNumber(Map<String, dynamic> row) {
    return row['order_number']?.toString() ??
        row['qre_request_id']?.toString() ??
        '-';
  }

  Future<void> generateReport() async {
    final userId = await _getUserId();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User data is not available.')),
      );
      return;
    }

    if (prescriptions.isEmpty) {
      await fetchPrescriptions();
    }

    if (prescriptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data available for the selected date range.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isGenerating = true);

    try {
      final response = await http.post(
        Uri.parse(
            AppConfig.buildApiUrl('generate_pharmacy_prescription_report')),
        body: {
          'from_date': fromDateController.text,
          'to_date': toDateController.text,
          'usr_id': userId.toString(),
        },
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final downloadUrl = responseData['download_url']?.toString() ?? '';
        final note = responseData['note']?.toString() ??
            'Use your 8-digit report decryption code to open the PDF.';

        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Report Ready'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(responseData['message']?.toString() ??
                    'Your encrypted report is ready.'),
                const SizedBox(height: 12),
                Text(note,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700])),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
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
                  child: const Text('Download PDF'),
                ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ??
                'No data available for the selected date range.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isGenerating = false);
    }
  }

  Widget _buildPreviewTable() {
    if (isLoadingPreview) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (prescriptions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'No prescriptions found for the selected date range.',
          style: TextStyle(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          const Color(0XFF4675C0).withOpacity(0.1),
        ),
        columns: const [
          DataColumn(label: Text('Order#', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Medicine', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Refills', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Provider', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: prescriptions.map((row) {
          final date = row['qit_created_dt']?.toString() ?? '';
          final shortDate = date.length >= 10 ? date.substring(0, 10) : date;
          return DataRow(cells: [
            DataCell(Text(_orderNumber(row))),
            DataCell(Text(row['qit_item_name']?.toString() ?? '')),
            DataCell(Text(row['refill_count']?.toString() ?? '0')),
            DataCell(Text(row['provider_name']?.toString() ?? '-')),
            DataCell(Text(shortDate)),
            DataCell(Text(row['qit_qty']?.toString() ?? '')),
          ]);
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Prescription Reports',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: theme.colorScheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: fromDateController,
              decoration: const InputDecoration(
                labelText: 'From Date',
                suffixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              onTap: () => _selectDate(context, true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: toDateController,
              decoration: const InputDecoration(
                labelText: 'To Date',
                suffixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              onTap: () => _selectDate(context, false),
            ),
            const SizedBox(height: 12),
            Text(
              'Reports are generated on the server and encrypted with your 8-digit code sent to your email.',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _buildPreviewTable(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            isGenerating
                ? const Center(child: CircularProgressIndicator())
                : CustomElevatedButton(
                    text: 'Generate Report',
                    onPressed: generateReport,
                  ),
          ],
        ),
      ),
    );
  }
}
