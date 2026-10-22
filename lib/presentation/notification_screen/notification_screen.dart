import 'package:flutter/material.dart';
import '../nav_bar/navbar_widget.dart'; // Import the Navbar widget
import '../../core/config/app_config.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'widgets/notification_item_widget.dart';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
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
      Uri.parse(AppConfig.buildApiUrl('update_nustatus')),
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
        return;
      }

      final Map<String, dynamic> userData = json.decode(userDataString);
      final int? userId = userData['id'];

      if (userId == null) {
        print("User ID is not available in userData");
        return;
      }

      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('get_user_notification')),
        body: {'usr_id': userId.toString()},
      );

      //print(response.body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Notification API Response: $data"); // 👈 log structure

        setState(() {
          // if API returns list directly
          quotations = data is List ? data : (data['quotations'] ?? []);
          isLoading = false;
        });

        _noti_update(userId);
      } else {
        print("Failed to fetch quotations: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching quotations: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Notifications",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        backgroundColor: Color(0XFF4675C0),
        elevation: 0,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${quotations.length} notifications",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      drawer: Navbar(scaffoldKey: _scaffoldKey),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0XFF4675C0).withOpacity(0.05),
              Colors.grey[50]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 16),
              Expanded(
                child: isLoading
                    ? _buildLoadingState()
                    : quotations.isEmpty
                        ? _buildEmptyState()
                        : _buildEnhancedNotificationList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0XFF4675C0)),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Loading notifications...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Please wait while we fetch your data',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.notifications_none_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedNotificationList() {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      separatorBuilder: (context, index) => SizedBox(height: 12),
      itemCount: quotations.length,
      itemBuilder: (context, index) {
        final quotation = quotations[index];

        final String notiType = quotation['noti_type']?.toString() ?? '';
        final String qreId = quotation['noti_qre_id']?.toString() ?? '';
        final String rawRemark =
            quotation['noti_remark']?.toString().trim() ?? 'Notification';
        final String requestId = quotation['id']?.toString().trim() ?? '';

        final String displayTitle = rawRemark;

        final bool openQuotationView = qreId.isNotEmpty &&
            (notiType == 'quotation_expiry_warning' ||
                notiType == 'quotation_hold_approved' ||
                notiType == 'quotation_hold_rejected' ||
                notiType == 'payment_reminder' ||
                notiType == 'quotation_soft_deleted');

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                if (openQuotationView) {
                  Navigator.pushNamed(
                    context,
                    '/quotation_view_screen',
                    arguments: {'rid': qreId},
                  );
                } else if (requestId.isNotEmpty) {
                  Navigator.pushNamed(
                    context,
                    '/quotation_list_screen',
                    arguments: {'Requestid': requestId},
                  );
                }
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notification icon
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0XFF4675C0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.notifications,
                      color: Color(0XFF4675C0),
                      size: 20,
                    ),
                  ),

                  SizedBox(width: 16),

                  // Notification content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Notification title/remark
                        Text(
                          displayTitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        SizedBox(height: 8),

                        // Date
                        if (quotation['noti_created_dt']
                                ?.toString()
                                .isNotEmpty ==
                            true)
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 6),
                              Text(
                                _formatDate(
                                    quotation['noti_created_dt']?.toString() ??
                                        ''),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  // Status indicator
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: quotation['noti_status']
                                  ?.toString()
                                  .toLowerCase() ==
                              'read'
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      quotation['noti_status']
                                  ?.toString()
                                  .toLowerCase() ==
                              'read'
                          ? 'Read'
                          : 'New',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: quotation['noti_status']
                                    ?.toString()
                                    .toLowerCase() ==
                                'read'
                            ? Colors.green[700]
                            : Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(String dateString) {
    try {
      if (dateString.contains('T')) {
        DateTime date = DateTime.parse(dateString);
        return "${date.day}/${date.month}/${date.year}";
      } else {
        return dateString;
      }
    } catch (e) {
      return dateString;
    }
  }
}
