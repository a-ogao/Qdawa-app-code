import 'package:flutter/material.dart';
import '../../doctor/navbar/navbar_widget.dart'; // Import the Navbar widget
import '../../../core/config/app_config.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'widgets/notification_item_widget.dart';

class DoctorNotificationScreen extends StatefulWidget {
  @override
  _DoctorNotificationScreenState createState() =>
      _DoctorNotificationScreenState();
}

class _DoctorNotificationScreenState extends State<DoctorNotificationScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController searchController = TextEditingController();
  List<dynamic> quotations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchQuotations();
  }

  Future<void> _noti_update(int myid) async {
    final response = await http.post(
      Uri.parse(AppConfig.buildApiUrl('update_nstatus')),
      body: {'usr_id': myid.toString()},
    );
    if (response.statusCode == 200) {
      print("Status Updated: ${response.statusCode}");
    } else {
      print('Unable to Update');
    }
  }

  Future<void> _fetchQuotations() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userDataString = prefs.getString('userData');

      if (userDataString == null) {
        print("User data is not available");
        setState(() {
          isLoading = false;
        });
        return;
      }

      final Map<String, dynamic> userData = json.decode(userDataString);
      final int? userId = userData['id'];

      if (userId == null) {
        print("User ID is not available in userData");
        setState(() {
          isLoading = false;
        });
        return;
      }

      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('get_doctor_notification')),
        body: {'usr_id': userId.toString()},
      );

      print("Doctor Notification API Response: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);

          setState(() {
            // Handle different response formats
            if (data is List) {
              quotations = data;
            } else if (data is Map<String, dynamic>) {
              quotations = data['quotations'] ??
                  data['notifications'] ??
                  data['data'] ??
                  [];
            } else {
              quotations = [];
            }
            isLoading = false;
          });

          _noti_update(userId);
        } catch (e) {
          print("Error parsing response JSON: $e");
          setState(() {
            quotations = [];
            isLoading = false;
          });
        }
      } else {
        print("Failed to fetch quotations: ${response.statusCode}");
        print("Response body: ${response.body}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching quotations: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // ✅ Fixed key reference
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Notifications",
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      drawer: Navbar(scaffoldKey: _scaffoldKey),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : quotations.isEmpty
                      ? Center(child: Text("No Notifcation available"))
                      : _buildQuotationList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotationList() {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      separatorBuilder: (context, index) => Divider(
        thickness: 1.5,
        color: Colors.grey[300],
      ),
      itemCount: quotations.length,
      itemBuilder: (context, index) {
        final quotation = quotations[index];

        return Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: QuotationRequestItemWidget(
            Requestid: quotation['id']?.toString() ?? '',
            requeststatus: quotation['noti_remark']?.toString() ?? '',
            requestdate: quotation['noti_created_dt']?.toString() ?? '',
            qstatus: quotation['noti_status']?.toString() ?? '',
          ),
        );
      },
    );
  }
}
