import 'package:flutter/material.dart';
import '../../pharmacy/nav_bar/navbar_widget.dart';
import 'widgets/quotationsgrid_item_widget.dart';
import 'widgets/gridquotation_item_widget.dart';
import '../../../core/app_export.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/notification_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PharmacyDashboardScreen extends StatefulWidget {
  PharmacyDashboardScreen({Key? key}) : super(key: key);

  @override
  _PharmacyDashboardScreenState createState() =>
      _PharmacyDashboardScreenState();
}

class _PharmacyDashboardScreenState extends State<PharmacyDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Map<String, dynamic> counters = {
    "quotations": 0,
    "orders": 0,
    "totalAmount": "KSH 0",
    "delivered": 0,
    "notification": 0,
  };
  List<Map<String, dynamic>> orderss = [];
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    print("=== PHARMACY DASHBOARD INITIALIZED ===");
    print("Starting to fetch counters and orders...");
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
    final quotationId = data['quotation_id'];

    if (type == 'quotation_received' || type == 'quotation_accepted' || type == 'quotation_rejected') {
      if (quotationId != null) {
        // Navigate to quotation requests
        Navigator.pushNamed(context, '/quotationRequestsPharmacyScreen');
      }
    } else if (type == 'order_placed' || type == 'order_ready') {
      if (orderId != null) {
        // Navigate to order list
        Navigator.pushNamed(context, '/orderListPharmacyScreen');
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

    final url = Uri.parse(AppConfig.buildApiUrl('getLastThreepOrders'));

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
                "pha_first_name": order["pha_first_name"] ?? "Unknown Pharmacy",
                "ord_order_status": order["ord_order_status"] ?? "Unknown",
                "ord_total_amount":
                    "-KSH ${order["ord_total_amount"].toString()}", // Convert int to String
                "ord_created_dt": order["ord_created_dt"] != null
                    ? order["ord_created_dt"].toString()
                    : "No Date",
                "color": order["ord_order_status"] == "Delivered"
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

      print("\n🔍 === PHARMACY COUNTER API REQUEST ===");
      print("API URL: ${AppConfig.buildApiUrl('pharmacycounters')}");
      print("User ID being sent: $userId");
      print("Request Body: {'usr_id': '${userId.toString()}'}");
      print("User Data: $userData");
      print("=== END API REQUEST INFO ===\n");

      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('pharmacycounters')),
        body: {'usr_id': userId.toString()},
      );
      if (response.statusCode == 200) {
        // Check if response is valid JSON (not HTML error page)
        if (response.body.trim().startsWith('{') ||
            response.body.trim().startsWith('[')) {
          try {
            final decodedData = json.decode(response.body);
            setState(() {
              counters = decodedData;

              // Print comprehensive counter stats
              print("=== PHARMACY DASHBOARD COUNTER STATS ===");
              print("Response Status: ${response.statusCode}");
              print("Raw Response: ${response.body}");
              print("Decoded Data: $decodedData");
              print("Counter Keys: ${counters.keys.toList()}");

              // Print individual counter values
              counters.forEach((key, value) {
                print("$key: $value (${value.runtimeType})");
              });

              // Highlight specific statistics
              print("\n📊 STATISTICS BREAKDOWN:");
              print("   Prescriptions: ${counters["quotations"] ?? 0}");
              print("   OTC: ${counters["otc"] ?? 0}");
              print("   Total Sales: ${counters["totalAmount"] ?? "KSH 0"}");
              print("   Customers: ${counters["patient"] ?? 0}");
              print("   ⚠️  PENDING: ${counters["pending"] ?? 0}");
              print("   Dispatched: ${counters["delivered"] ?? 0}");
              print("   Notifications: ${counters["notification"] ?? 0}");

              print("=== END COUNTER STATS ===");
            });
          } catch (jsonError) {
            print("=== JSON PARSING ERROR ===");
            print("Error: $jsonError");
            print("Response was supposed to be JSON but parsing failed");
            print(
                "Response body preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}");
            print("=== END JSON ERROR ===");
            _setDefaultCounters();
          }
        } else {
          print("=== SERVER RETURNED HTML ERROR PAGE ===");
          print("Status Code: ${response.statusCode}");
          print("Expected JSON but got HTML. This indicates a server error.");

          // Extract error message if it's an HTML error page
          if (response.body.contains('SQLSTATE') ||
              response.body.contains('QueryException')) {
            print("DATABASE ERROR DETECTED:");
            if (response.body.contains('Column not found')) {
              print("- Missing database column");
            }
            if (response.body.contains('payment_status')) {
              print("- Issue with 'payment_status' column in database");
            }
          }

          print(
              "Response preview: ${response.body.substring(0, response.body.length > 300 ? 300 : response.body.length)}");
          print("=== END HTML ERROR ===");
          _setDefaultCounters();
        }
      } else {
        print("Failed to fetch counters. Status code: ${response.statusCode}");
        print("Response body: ${response.body}");
        _setDefaultCounters();
      }
    } catch (e) {
      print("=== ERROR FETCHING PHARMACY COUNTERS ===");
      print("Error: $e");
      print("Error Type: ${e.runtimeType}");
      if (e is FormatException) {
        print("JSON Format Error - Invalid response format");
      } else if (e is http.ClientException) {
        print("Network Error - Check internet connection");
      }
      print("=== END ERROR LOG ===");

      _setDefaultCounters();
    }
  }

  // Helper method to set default counter values
  void _setDefaultCounters() {
    setState(() {
      counters = {
        "quotations": 0,
        "orders": 0,
        "totalAmount": "KSH 0",
        "delivered": 0,
        "notification": 0,
        "otc": 0,
        "patient": 0,
      };
      print("Set default counter values due to server error");
    });
  }

  // Method to manually print current counter stats (useful for debugging)
  void printCurrentCounters() {
    print("=== CURRENT PHARMACY COUNTER STATS ===");
    print("Counters Map: $counters");
    print("Individual Values:");
    counters.forEach((key, value) {
      print("  $key: $value (${value.runtimeType})");
    });
    print("Is Loading: $isLoading");
    print("Orders Count: ${orderss.length}");
    print("=== END CURRENT STATS ===");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Pharmacy Dashboard",
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
                    Navigator.pushNamed(
                      context,
                      '/pharmacy_notification',
                    );
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
                          border: Border.all(color: Colors.white, width: 1.5),
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
                SizedBox(height: 20),
                _buildMainContent(context),
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 18.0),
      child: Column(
        children: [
          // Services label
          Row(
            children: [
              Text(
                "Services",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildQuotationsGrid(context),
          SizedBox(height: 20.0),
          _buildStatsWidget(), // Newly added Stats section
          SizedBox(height: 50.0),
          _buildOrdersWidget(), // Newly added Orders section
        ],
      ),
    );
  }

  Widget _buildStatsWidget() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
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
          SizedBox(height: 16),
          GridView(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              childAspectRatio: 1.8,
            ),
            children: [
              _buildStatCard("Prescriptions", counters["quotations"].toString(),
                  Icons.medication, Color(0XFF4675C0), () {
                Navigator.pushNamed(
                    context, '/quotation_requests_pharmacy_screen');
              }),
              _buildStatCard(
                  "OTC",
                  (counters["otc"] == null ||
                          counters["otc"].toString().isEmpty)
                      ? '0'
                      : counters["otc"].toString(),
                  Icons.local_pharmacy,
                  Colors.red, () {
                Navigator.pushNamed(context, '/pharmacy_usersymptoms_screen');
              }),
              _buildStatCardWithText(
                  "Total Sales",
                  "" + counters["totalAmount"].toString(),
                  "KSH",
                  Colors.green, () {
                Navigator.pushNamed(context, '/payment_pharmacy_screen');
              }),
              _buildStatCard(
                  "Customers",
                  (counters["patient"] == null ||
                          counters["patient"].toString().isEmpty)
                      ? '0'
                      : counters["patient"].toString(),
                  Icons.people,
                  Colors.purple, () {
                Navigator.pushNamed(context, '/pharmacy_customers_list_screen');
              }),
              _buildStatCard(
                  "Pending",
                  (counters["pending"] == null ||
                          counters["pending"].toString().isEmpty)
                      ? '0'
                      : counters["pending"].toString(),
                  Icons.pending,
                  Colors.orange, () {
                Navigator.pushNamed(context, '/Pending_order_list_screen');
              }),
              _buildStatCard("Dispatched", counters["delivered"].toString(),
                  Icons.local_shipping, Colors.teal, () {
                Navigator.pushNamed(context, '/dPharmacy_order_list_screen');
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
        padding: EdgeInsets.all(6.0),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            SizedBox(height: 3.0),
            Text(title,
                style: TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700])),
            SizedBox(height: 1.0),
            Text(value,
                style: TextStyle(
                    fontSize: 13.0, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCardWithText(String title, String value, String textIcon,
      Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(6.0),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(textIcon,
                style: TextStyle(
                    fontSize: 14.0, fontWeight: FontWeight.bold, color: color)),
            SizedBox(height: 3.0),
            Text(title,
                style: TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700])),
            SizedBox(height: 1.0),
            Text(value,
                style: TextStyle(
                    fontSize: 13.0, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersWidget() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "My Orders",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/Pharmacy_order_list_screen');
                },
                child: Text(
                  "View All",
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4675C0),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (orderss.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Column(
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 48,
                    color: Color(0xFF9CA3AF),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "No Orders Yet",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Your recent orders will appear here",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...orderss.map((order) {
              return Container(
                margin: EdgeInsets.only(bottom: 12.0),
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48.0,
                      height: 48.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF4675C0).withOpacity(0.1),
                      ),
                      child: Icon(
                        Icons.local_pharmacy_outlined,
                        color: Color(0xFF4675C0),
                        size: 24.0,
                      ),
                    ),
                    SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            order["pha_first_name"] as String,
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          SizedBox(height: 4.0),
                          Text(
                            "${order["ord_order_status"] as String}${order["ord_created_dt"] != null ? " • ${order["ord_created_dt"]}" : ""}",
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          order["ord_total_amount"] as String,
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w700,
                            color: order["color"] as Color,
                          ),
                        ),
                        SizedBox(height: 4.0),
                        Container(
                          width: 8.0,
                          height: 8.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: order["color"] as Color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildQuotationsGrid(BuildContext context) {
    final List<Map<String, dynamic>> gridItems = [
      {
        "title": "Quotations",
        "icon": Icons.description_outlined,
        "route": "/quotation_requests_pharmacy_screen",
        "color": Color(0xFF4675C0),
      },
      {
        "title": "Orders",
        "icon": Icons.shopping_bag_outlined,
        "route": "/Pharmacy_order_list_screen",
        "color": Color(0xFF10B981),
      },
      {
        "title": "Riders",
        "icon": Icons.delivery_dining_outlined,
        "route": "/riderlist_screen",
        "color": Color(0xFFF59E0B),
      },
      {
        "title": "Reports",
        "icon": Icons.assessment_outlined,
        "route": "/pharmacy_reports",
        "color": Color(0xFFEF4444),
      },
      {
        "title": "Messages",
        "icon": Icons.message_outlined,
        "route": "/pharmacy_notification",
        "color": Color(0xFF06B6D4),
      },
      {
        "title": "Doctors",
        "icon": Icons.medical_services_outlined,
        "route": "/ddoctor_list",
        "color": Color(0xFF8B5CF6),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
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
                  color: Colors.black.withValues(alpha: 0.08),
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
                    color: item["color"].withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item["icon"],
                    size: 28.0,
                    color: item["color"],
                  ),
                ),
                SizedBox(height: 14.0),
                Text(
                  item["title"],
                  style: TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
