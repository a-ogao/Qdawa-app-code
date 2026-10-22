import 'package:flutter/material.dart';
import '../../delivery/nav_bar/navbar_widget.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/notification_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DeliverydashboardScreen extends StatefulWidget {
  DeliverydashboardScreen({Key? key}) : super(key: key);

  @override
  _DeliverydashboardScreenState createState() =>
      _DeliverydashboardScreenState();
}

class _DeliverydashboardScreenState extends State<DeliverydashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Map<String, dynamic> counters = {
    "quotations": 0,
    "orders": 0,
    "totalAmount": "KSH 0",
    "delivered": 0,
    "notification": 0,
    "totalkm": 0,
  };
  List<Map<String, dynamic>> orderss = [];
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    fetchCounters();
    fetchOrders(); // Fetch orders when the screen loads
    _checkPendingNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionToken = prefs.getString('sessionToken');
      
      if (sessionToken != null && sessionToken.isNotEmpty) {
        // Check if device is already registered
        final isRegistered = await NotificationService.isDeviceRegistered();
        if (!isRegistered) {
          // Request permission and register device
          await NotificationService.requestPermissionAndRegister(sessionToken);
        }
      }
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  Future<void> _checkPendingNotifications() async {
    try {
      final notificationData = await NotificationService.getPendingNotification();
      if (notificationData != null) {
        _handleNotificationNavigation(notificationData);
      }
    } catch (e) {
      print('Error checking pending notifications: $e');
    }
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'];
    final orderId = data['order_id'];

    if (type == 'order_dispatched' || type == 'order_ready') {
      if (orderId != null) {
        // Navigate to delivery requests
        Navigator.pushNamed(context, '/deliveryrequests');
      }
    } else if (type == 'order_delivered') {
      if (orderId != null) {
        // Navigate to delivered orders
        Navigator.pushNamed(context, '/deliveryorders');
      }
    }
  }

  Future<void> fetchOrders() async {
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

    final url = Uri.parse(AppConfig.buildApiUrl('getLastThreedOrders'));

    try {
      final response = await http.post(url,
          body: {'usr_id': userId.toString()}); // Convert userId to String

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success']) {
          setState(() {
            orderss =
                List<Map<String, dynamic>>.from(data['orders'].map((order) {
              return {
                "pha_first_name": order["usr_username"] ?? "Unknown",
                "ord_order_status": order["del_delivery_status"] ?? "Unknown",
                "ord_total_amount":
                    "-KSH ${order["ord_delivery_charge"].toString()}", // Convert int to String
                "ord_created_dt": order["adr_address_1"] != null
                    ? order["adr_address_1"].toString()
                    : "No Date",
                "color": order["del_delivery_status"] == "Delivered"
                    ? Colors.green
                    : Colors.red,
              };
            }));
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching orders: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchCounters() async {
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
        Uri.parse(AppConfig.buildApiUrl('deliverycounters')),
        body: {'usr_id': userId.toString()},
      );
      if (response.statusCode == 200) {
        setState(() {
          counters = json.decode(response.body);
        });
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
          "Delivery Dashboard",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.menu,
            color: Colors.white,
          ),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () {
                  if (counters["notification"]?.toString() != "0" &&
                      counters["notification"]?.toString().isNotEmpty == true) {
                    Navigator.pushNamed(context, '/dnotification');
                  }
                },
                child: Container(
                  margin: EdgeInsets.only(right: 8.0),
                  height: 36.0,
                  width: 36.0,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications,
                    color: Colors.white,
                    size: 24.0,
                  ),
                ),
              ),
              (counters["notification"]?.toString() != "0" &&
                      counters["notification"]?.toString().isNotEmpty == true)
                  ? Positioned(
                      right: 0,
                      top: -6,
                      child: Container(
                        padding: EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 1.5,
                          ),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          counters["notification"].toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : SizedBox.shrink(),
            ],
          ),
        ],
        backgroundColor: Color(0XFF4675C0),
        elevation: 0,
      ),
      drawer: Navbar(scaffoldKey: _scaffoldKey),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0XFF4675C0).withValues(alpha: 0.05),
              Colors.grey[50]!,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 16), // Reduced from 20
                _buildMainContent(context),
                SizedBox(height: 16), // Reduced from 30
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Column(
      children: [
        _buildQuotationsGrid(context),
        SizedBox(height: 8.0), // Reduced by 10px (from 16.0)
        _buildStatsWidget(),
        SizedBox(height: 8.0), // Reduced by 10px (from 16.0)
        _buildOrdersWidget(),
      ],
    );
  }

  Widget _buildStatsWidget() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16), // Restored to proper padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Statistics",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8), // Further reduced from 12
          GridView(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 25.0, // Increased for more space between cards
              mainAxisSpacing: 25.0, // Increased for more space between cards
              childAspectRatio:
                  0.85, // Much taller cards to fit all content properly
            ),
            children: [
              _buildStatCard("Requests", counters["quotations"].toString(),
                  Icons.local_shipping, Color(0XFF4675C0), () {
                Navigator.pushNamed(context, '/delivery_requests');
              }),
              _buildStatCard(
                  "Picked-Up",
                  (counters["orders"] == null ||
                          counters["orders"].toString().isEmpty)
                      ? '0'
                      : counters["orders"].toString(),
                  Icons.done_all,
                  Colors.red, () {
                Navigator.pushNamed(context, '/pickeup_requests');
              }),
              _buildStatCardWithText(
                  "Total Earnings",
                  "" + counters["totalAmount"].toString(),
                  "KSH",
                  Colors.green, () {
                Navigator.pushNamed(context, '/delivery_orders');
              }),
              _buildStatCard(
                  "Delivered",
                  (counters["delivered"] == null ||
                          counters["delivered"].toString().isEmpty)
                      ? '0'
                      : counters["delivered"].toString(),
                  Icons.check_circle,
                  Colors.purple, () {
                Navigator.pushNamed(context, '/delivery_orders');
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16), // Restored to proper padding
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12), // Reduced from 16
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06), // Lighter shadow
              blurRadius: 8, // Reduced blur
              offset: Offset(0, 2), // Reduced offset
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12), // Restored to proper size
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24, // Restored to proper size
              ),
            ),
            SizedBox(height: 12), // Increased for better spacing
            Text(
              title,
              style: TextStyle(
                fontSize: 12, // Restored to readable size
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 25), // Increased for better spacing
            Text(
              value,
              style: TextStyle(
                fontSize: 18, // Restored to proper size
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCardWithText(String title, String value, String prefix,
      Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16), // Same as _buildStatCard
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12), // Same as _buildStatCard
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(alpha: 0.06), // Same as _buildStatCard
              blurRadius: 8,
              offset: Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12), // Same as _buildStatCard
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.attach_money,
                color: color,
                size: 24, // Same as _buildStatCard
              ),
            ),
            SizedBox(height: 12), // Same as _buildStatCard
            Text(
              title,
              style: TextStyle(
                fontSize: 12, // Same as _buildStatCard
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8), // Same as _buildStatCard
            Text(
              "$prefix $value",
              style: TextStyle(
                fontSize: 18, // Same as _buildStatCard
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersWidget() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("My Orders",
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context,
                      '/delivery_orders'); // Update with your actual route name
                },
                child: Text(
                  "View All",
                  style: TextStyle(fontSize: 14.0, color: Colors.blue),
                ),
              ),
            ],
          ),
        SizedBox(height: 10.0),

        // 🔥 FIX: Wrapped in SingleChildScrollView to prevent overflow
        SingleChildScrollView(
          child: Column(
            children: orderss.map((order) {
              return Container(
                margin: EdgeInsets.symmetric(vertical: 6.0),
                padding: EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 5.0)
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40.0,
                      height: 40.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade300,
                      ),
                    ),
                    SizedBox(width: 10.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(order["pha_first_name"] as String,
                              style: TextStyle(
                                  fontSize: 16.0, fontWeight: FontWeight.bold)),

                          // 🔥 FIX: Proper parentheses for ternary operator
                          Text(
                            "${order["ord_order_status"] as String}${order["ord_created_dt"] != null ? " on ${order["ord_created_dt"]}" : ""}",
                            style:
                                TextStyle(fontSize: 14.0, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      order["ord_total_amount"] as String,
                      style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: order["color"] as Color),
                    ),
                    SizedBox(width: 5.0),
                    Icon(Icons.circle, color: Colors.blue, size: 12.0),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildQuotationsGrid(BuildContext context) {
    final List<Map<String, dynamic>> gridItems = [
      {
        "title": "Delivery Requests",
        "icon": Icons.local_shipping_outlined,
        "route": "/delivery_requests",
        "color": Color(0XFF4675C0),
      },
      {
        "title": "My Deliveries",
        "icon": Icons.assignment_turned_in_outlined,
        "route": "/delivery_orders",
        "color": Color(0XFF10B981),
      },
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 0.0, bottom: 12.0),
            child: Text(
              "Services",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              childAspectRatio: 0.85,
            ),
            itemCount: gridItems.length,
            itemBuilder: (context, index) {
              final item = gridItems[index];
              return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, item["route"]);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15.0,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(14.0),
                        decoration: BoxDecoration(
                          color: item["color"].withOpacity(0.12),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: item["color"].withOpacity(0.2),
                              blurRadius: 8.0,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          item["icon"],
                          color: item["color"],
                          size: 26.0,
                        ),
                      ),
                      SizedBox(height: 10.0),
                      Text(
                        item["title"],
                        style: TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
