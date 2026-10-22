import 'package:flutter/material.dart';
import '../navbar/navbar_widget.dart'; // Import the Navbar widget
import 'widgets/gridquotation_item_widget.dart';
import 'widgets/quotationsgrid_item_widget.dart';
import '../../scan_prescription_screen/scan_prescription_screen.dart';
import '../write_prescription_screen/write_prescription_screen.dart';
import '../../../core/app_export.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/notification_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../../medicine_request.dart';

class DoctordashboardScreen extends StatefulWidget {
  DoctordashboardScreen({Key? key}) : super(key: key);

  @override
  _DoctordashboardScreenState createState() => _DoctordashboardScreenState();
}

class _DoctordashboardScreenState extends State<DoctordashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Map<String, dynamic> counters = {
    "quotations": 0,
    "orders": 0,
    "totalAmount": "KSH 0",
    "delivered": 0,
    "newPat": 0,
    "notification": 0,
  };
  List<Map<String, dynamic>> orderss = [];
  bool isLoading = true;
  bool isBannerLoading = true; // State to track banner loading
  String? bannerUrl; // Variable to store the banner URL
  String? actionType;
  String? actionValue;
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
    final prescriptionId = data['prescription_id'];

    if (type == 'prescription_received' || type == 'prescription_approved') {
      if (prescriptionId != null) {
        // Navigate to prescriptions screen
        Navigator.pushNamed(context, '/writtenprescriptions');
      }
    } else if (type == 'order_placed' || type == 'order_ready') {
      if (orderId != null) {
        // Navigate to order list
        Navigator.pushNamed(context, '/DorderListScreen');
      }
    }
  }

  Future<void> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location services are disabled.");
      return;
    }

    // Request permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Location permission denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("Location permission permanently denied.");
      return;
    }
  }

  Future<void> fetchBanner() async {
    try {
      final response = await http.post(Uri.parse(
          AppConfig.buildApiUrl('getBanner'))); // Replace with your API URL
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // print(data);
        setState(() {
          // bannerUrl = data['banner_base64']; // Store Base64 string
          String base64String = data['banner_base64'];

          // Remove "data:image/...;base64," if present
          if (base64String.contains(",")) {
            base64String = base64String.split(",")[1];
          }
          bannerUrl = base64String.trim(); // Trim extra spaces
          actionType = data['advertisement']['click_action'] ?? "";
          actionValue = data['advertisement']['action_value'] ?? "";
          isBannerLoading = false;
        });
      } else {
        setState(() => isBannerLoading = false);
      }
    } catch (e) {
      print("Error fetching banner: $e");
      setState(() => isBannerLoading = false);
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

    final url = Uri.parse(AppConfig.buildApiUrl('getLastThreeOrders'));

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
      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('doctorcounters')),
        body: {'usr_id': userId.toString()},
      );
      //print(response.body);
      if (response.statusCode == 200) {
        final decodedCounters = json.decode(response.body);
        setState(() {
          counters = decodedCounters;
        });
        
        // If quotations counter is 0 or null, fetch actual count from prescription list API
        final quotationsCount = decodedCounters["quotations"];
        if (quotationsCount == null || quotationsCount == 0) {
          _fetchPrescriptionCount();
        }
      }
    } catch (e) {
      print("Error fetching quotations: $e");
    }
  }

  Future<void> _fetchPrescriptionCount() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userDataString = prefs.getString('userData');

      if (userDataString == null) {
        return;
      }

      final Map<String, dynamic> userData = json.decode(userDataString);
      final int? userId = userData['id'];

      if (userId == null) {
        return;
      }

      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('get_quotation_drequest')),
        body: {'usr_id': userId.toString()},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final quotationsList = data['quotations'] ?? [];
        final actualCount = quotationsList.length;
        
        // Update the counter with the actual count if it's greater than 0
        if (actualCount > 0) {
          setState(() {
            counters["quotations"] = actualCount;
          });
        }
      }
    } catch (e) {
      print("Error fetching prescription count: $e");
    }
  }

  Future<void> _handleBannerClick() async {
    if (actionType == 'prescription') {
      // Save action data in local storage
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('action_type', actionType.toString());
      await prefs.setString('action_value', actionValue.toString());

      // Navigate to Scan Prescription Page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ScanPrescriptionScreen()),
      );
    } else if (actionType == 'url') {
      // Open URL in browser
      final Uri url = Uri.parse(actionValue.toString());

      await launchUrl(url, mode: LaunchMode.externalApplication);
      // await launchUrl(url, mode: LaunchMode.inAppBrowserView);
    }
  }

  Widget _buildBanner() {
    return GestureDetector(
      onTap: () => _handleBannerClick(),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 18.0),
        width: double.infinity,
        height: 120.0,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: Colors.grey[300],
        ),
        child: isBannerLoading
            ? Center(child: CircularProgressIndicator()) // Show loader
            : (bannerUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: Image.memory(
                      base64Decode(bannerUrl!),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 200.0,
                    ),
                  )
                : Center(child: Text("No Banner Available"))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Doctor Dashboard",
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
                  Navigator.pushNamed(context, '/doctor_notification');
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
                _buildAddBalanceSection(context),
                SizedBox(height: 20),
                _buildWritePrescriptionSection(context),
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

  Widget _buildAddBalanceSection(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScanPrescriptionScreen(),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 18.0),
        padding: EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8.0,
              spreadRadius: 1.0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Scan Prescription",
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(
              Icons.qr_code_scanner,
              size: 40.0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWritePrescriptionSection(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WritePrescriptionScreen(),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 18.0),
        padding: EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8.0,
              spreadRadius: 1.0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Write Prescription",
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(
              Icons.edit_note,
              size: 40.0,
            ),
          ],
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
          // My Orders section hidden for doctor dashboard
          // SizedBox(height: 50.0),
          // _buildOrdersWidget(), // Newly added Orders section
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
              _buildStatCard(
                  "Patients",
                  (counters["patientCount"] == null ||
                          counters["patientCount"].toString().isEmpty)
                      ? '0'
                      : counters["patientCount"].toString(),
                  Icons.people,
                  Colors.purple, () {
                Navigator.pushNamed(context, '/patientlist_screen');
              }),
              _buildStatCard(
                  "Prescriptions",
                  (counters["quotations"] == null ||
                          counters["quotations"].toString().isEmpty)
                      ? '0'
                      : counters["quotations"].toString(),
                  Icons.description_outlined, Color(0xFF4675C0), () {
                Navigator.pushNamed(
                    context, '/quotationrequest_dpatient_screen');
              }),
              _buildStatCard("New Patients", counters["newPat"].toString(),
                  Icons.person_add, Colors.blue, () {
                Navigator.pushNamed(context, '/patientlist_screen');
              }),
              _buildStatCard("Orders", counters["orders"].toString(),
                  Icons.shopping_bag_outlined, Colors.red, () {
                Navigator.pushNamed(context, '/dorder_list_screen');
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

  Widget _buildStatCardd(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5.0)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title,
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
          SizedBox(height: 10.0),
          Text(value,
              style: TextStyle(
                  fontSize: 18.0, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildOrdersWidget() {
    return Column(
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
                Navigator.pushNamed(
                    context, '/'); // Update with your actual route name
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
    );
  }

  Widget _buildQuotationsGrid(BuildContext context) {
    final List<Map<String, dynamic>> gridItems = [
      // First item "Quotations" hidden for doctor login
      {
        "title": "Patient",
        "icon": Icons.person_outline,
        "route": "/patientlist_screen",
        "color": Color(0xFF10B981),
      },
      {
        "title": "Pharmacy",
        "icon": Icons.local_pharmacy_outlined,
        "route": "/dupharmacy_list",
        "color": Color(0xFFF59E0B),
      },
      {
        "title": "Messages",
        "icon": Icons.message_outlined,
        "route": "/doctor_notification",
        "color": Color(0xFF06B6D4),
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
