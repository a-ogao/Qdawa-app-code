import 'package:flutter/material.dart';
import '../nav_bar/navbar_widget.dart'; // Import the Navbar widget
import '../scan_prescription_screen/scan_prescription_screen.dart';
import '../upload_prescription_screen/upload_prescription_screen.dart';
import '../../core/config/app_config.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/active_patient_service.dart';
import '../../core/utils/patient_api_context.dart';
import '../../widgets/patient_profile_switcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../medicine_request.dart';
import '../labReport.dart';
import '../otc_order/otc_order_screen.dart';

class DashboardScreen extends StatefulWidget {
  DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Map<String, dynamic> counters = {
    "quotations": 0,
    "orders": 0,
    "totalAmount": "KSH 0",
    "delivered": 0,
    "refill": 0,
    "reminder": 0,
    "notification": 0,
  };
  List<Map<String, dynamic>> orderss = [];
  List<Map<String, dynamic>> expiringQuotations = [];
  bool isLoading = true;
  bool isBannerLoading = true; // State to track banner loading
  String? bannerUrl; // Variable to store the banner URL
  String? actionType;
  String? actionValue;

  @override
  void initState() {
    super.initState();
    ActivePatientService.instance.initialize();
    _getLocation(); // Call function on page load
    _initializeNotifications();
    fetchBanner(); // Fetch banner on screen load
    fetchCounters();
    fetchOrders();
    fetchExpiringQuotations();
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

    if (type == 'order_placed' || type == 'order_ready' || type == 'order_dispatched' || type == 'order_delivered') {
      if (orderId != null) {
        // Navigate to order details or order list
        Navigator.pushNamed(context, '/order_list_screen');
      }
    } else if (type == 'quotation_expiry_warning' ||
        type == 'quotation_hold_approved' ||
        type == 'quotation_hold_rejected') {
      final qreId = data['request_id'] ?? data['qre_id'];
      if (qreId != null) {
        Navigator.pushNamed(
          context,
          '/quotation_view_screen',
          arguments: {'rid': qreId.toString()},
        );
      }
    } else if (type == 'quotation_received' || type == 'quotation_accepted' || type == 'quotation_rejected') {
      if (quotationId != null) {
        // Navigate to quotations screen
        Navigator.pushNamed(context, '/quotationrequest_patient_screen');
      }
    } else if (type == 'payment_success' || type == 'payment_failed') {
      // Navigate to payments screen
      Navigator.pushNamed(context, '/patient_payments_screen');
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
        //print(response.body);
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
    try {
      final body = await PatientApiContext.body();
      if (!body.containsKey('usr_id')) {
        print("User data is not available");
        return;
      }

    final url = Uri.parse(AppConfig.buildApiUrl('getLastThreeOrders'));

    try {
      final response = await http.post(url, body: body);

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
    } catch (e) {
      print("Error preparing orders request: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _reloadPatientData() {
    setState(() => isLoading = true);
    fetchCounters();
    fetchOrders();
    fetchExpiringQuotations();
    return Future.value();
  }

  Future<void> fetchExpiringQuotations() async {
    try {
      final body = await PatientApiContext.body();
      if (!body.containsKey('usr_id')) return;

      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('get_patient_expiring_quotations')),
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          expiringQuotations = List<Map<String, dynamic>>.from(
            data['expiring_quotations'] ?? [],
          );
        });
      }
    } catch (e) {
      print('Error fetching expiring quotations: $e');
    }
  }

  Widget _buildExpiringQuotationsWidget() {
    if (expiringQuotations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
              const SizedBox(width: 8),
              const Text(
                'Quotations Expiring Soon',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...expiringQuotations.map((item) {
            final requestNo = item['request_no']?.toString() ?? '';
            final pharmacy = item['pharmacy_name']?.toString() ?? 'Pharmacy';
            final hoursLeft = item['hours_until_auto_delete']?.toString() ?? '?';
            final qreId = item['qre_id']?.toString() ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(
                  'Quotation #$requestNo',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '$pharmacy • Expires in $hoursLeft hour(s). Will be removed automatically unless you pay or request a hold.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  if (qreId.isNotEmpty) {
                    Navigator.pushNamed(
                      context,
                      '/quotation_view_screen',
                      arguments: {'rid': qreId},
                    );
                  }
                },
              ),
            );
          }),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Future<void> fetchCounters() async {
    try {
      final body = await PatientApiContext.body();
      if (!body.containsKey('usr_id')) {
        print("User data is not available");
        return;
      }

      print("Fetching counters for user ID: ${body['usr_id']}");

      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('usercounters')),
        body: body,
      );
      print("--------------------------------=====================");
      print("Response status: ${response.statusCode}");
      print(
          "Response body preview: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}");

      if (response.statusCode == 200) {
        // Check if response is valid JSON (not HTML error page)
        if (response.body.trim().startsWith('{') ||
            response.body.trim().startsWith('[')) {
          try {
            final decodedData = json.decode(response.body);
            setState(() {
              counters = decodedData;
              print("Counters loaded successfully: $counters");
            });
          } catch (jsonError) {
            print("JSON decode error: $jsonError");
            print("Response body: ${response.body}");
            // Set default values when JSON parsing fails
            setState(() {
              counters = {
                'quotations': 0,
                'orders': 0,
                'totalAmount': 0,
                'delivered': 0,
                'refill': 0,
                'reminder': 0,
                'notification': 0,
                'porders': 0,
              };
            });
          }
        } else {
          print("API returned HTML error page instead of JSON");
          print("Response body: ${response.body}");
          // Set default values when API returns HTML error
          setState(() {
            counters = {
              'quotations': 0,
              'orders': 0,
              'totalAmount': 0,
              'delivered': 0,
              'refill': 0,
              'reminder': 0,
              'notification': 0,
              'porders': 0,
            };
          });
        }
      } else {
        print("HTTP error: ${response.statusCode}");
        print("Response body: ${response.body}");
        // Set default values on HTTP error
        setState(() {
          counters = {
            'quotations': 0,
            'orders': 0,
            'totalAmount': 0,
            'delivered': 0,
            'refill': 0,
            'reminder': 0,
            'notification': 0,
            'porders': 0,
          };
        });
      }
    } catch (e) {
      print("Error fetching counters: $e");
      // Set default values on any error
      setState(() {
        counters = {
          'quotations': 0,
          'orders': 0,
          'totalAmount': 0,
          'delivered': 0,
          'refill': 0,
          'reminder': 0,
          'notification': 0,
          'porders': 0,
        };
      });
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
        margin: EdgeInsets.symmetric(horizontal: 20.0),
        width: double.infinity,
        height: 150.0,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 15.0,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.0),
          child: isBannerLoading
              ? Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF4675C0).withOpacity(0.15),
                        Color(0xFF4675C0).withOpacity(0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF4675C0)),
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 12),
                        Text(
                          "Loading Banner...",
                          style: TextStyle(
                            color: Color(0xFF4675C0).withOpacity(0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : (bannerUrl != null
                  ? Stack(
                      children: [
                        Image.memory(
                          base64Decode(bannerUrl!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 150.0,
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.3),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            height: 40,
                          ),
                        ),
                      ],
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF4675C0).withOpacity(0.15),
                            Color(0xFF4675C0).withOpacity(0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Color(0xFF4675C0).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                size: 32,
                                color: Color(0xFF4675C0).withOpacity(0.6),
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              "No Banner Available",
                              style: TextStyle(
                                color: Color(0xFF4675C0).withOpacity(0.8),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Tap to refresh",
                              style: TextStyle(
                                color: Color(0xFF4675C0).withOpacity(0.6),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "QuikDawa",
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.menu,
            color: Colors.white,
            size: 28,
          ),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer(); // Open the drawer
          },
        ),
        actions: [
          PatientProfileSwitcher(onSwitched: _reloadPatientData),
          Stack(
            clipBehavior: Clip.none, // Allow badge to overflow
            children: [
              Container(
                margin: EdgeInsets.only(right: 16.0),
                height: 40.0,
                width: 40.0,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  onPressed: () {
                    if (counters["notification"]?.toString() != "0" &&
                        counters["notification"]?.toString().isNotEmpty ==
                            true) {
                      Navigator.pushNamed(context, '/notification');
                    } else {
                      Navigator.pushNamed(context, '/notification');
                    }
                  },
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 22.0,
                  ),
                ),
              ),
              (counters["notification"]?.toString() != "0" &&
                      counters["notification"]?.toString().isNotEmpty == true)
                  ? Positioned(
                      right: 12,
                      top: -4,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.0, vertical: 2.0),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        constraints: BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          counters["notification"].toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.0,
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
        backgroundColor: Color(0xFF4675C0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      drawer: Navbar(scaffoldKey: _scaffoldKey), // Use the Navbar widget here
      body: SafeArea(
        child: Column(
          children: [
            const ManagingPatientBanner(),
            Expanded(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 20.0),
              _buildBanner(), // Banner Widget
              SizedBox(height: 20.0),
              _buildExpiringQuotationsWidget(),
              SizedBox(height: 20.0),
              _buildQuickActionsSection(),
              SizedBox(height: 30.0),
              _buildMainContent(context),
              SizedBox(height: 40.0),
              _buildFooter(),
              SizedBox(height: 30.0),
            ],
          ),
        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quick Actions",
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 16.0),

          // Scan Prescription Bar
          _buildScanPrescriptionBar(),

          SizedBox(height: 16.0),

          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  "Upload Prescription",
                  Icons.cloud_upload,
                  Color(0xFF4675C0),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UploadPrescriptionScreen(),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: 12.0),
              Expanded(
                child: _buildQuickActionCard(
                  "Request Medicine",
                  Icons.medical_services,
                  Color(0xFF10B981),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MedicineRequestScreen(),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: 12.0),
              Expanded(
                child: _buildQuickActionCard(
                  "Upload Report",
                  Icons.insert_drive_file,
                  Color(0xFFF59E0B),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PReportsPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 12.0),
          _buildQuickActionCard(
            "Place order for general medicine",
            Icons.local_pharmacy,
            Color(0xFF0F766E),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OtcOrderScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 18.0, horizontal: 12.0),
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
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8.0,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: color,
                size: 26.0,
              ),
            ),
            SizedBox(height: 10.0),
            Text(
              title,
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
  }

  Widget _buildScanPrescriptionBar() {
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
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4675C0),
              Color(0xFF4675C0).withOpacity(0.8),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF4675C0).withOpacity(0.3),
              blurRadius: 20.0,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.qr_code_scanner,
                color: Colors.white,
                size: 32.0,
              ),
            ),
            SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scan Prescription',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    'Capture with camera & analyze with AI',
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.white.withOpacity(0.9),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.8),
              size: 20.0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          _buildQuotationsGrid(context),
          SizedBox(height: 30.0),
          _buildStatsWidget(),
          SizedBox(height: 50.0), // Increased spacing to prevent overlap
          _buildOrdersWidget(),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, VoidCallback onTap) {
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
            Icon(
              _getIconForStat(title),
              color: color,
              size: 18,
            ),
            SizedBox(height: 3.0),
            Text(
              title,
              style: TextStyle(
                fontSize: 11.0,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.0),
            Text(
              value,
              style: TextStyle(
                fontSize: 13.0,
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
            Text(
              textIcon,
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 3.0),
            Text(
              title,
              style: TextStyle(
                fontSize: 11.0,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.0),
            Text(
              value,
              style: TextStyle(
                fontSize: 13.0,
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

  IconData _getIconForStat(String title) {
    switch (title.toLowerCase()) {
      case 'prescriptions':
        return Icons.description_outlined;
      case 'pending orders':
        return Icons.pending_outlined;
      case 'total sales':
      case 'total payments':
        return Icons.payments_outlined;
      case 'delivered':
        return Icons.local_shipping_outlined;
      case 'refill':
        return Icons.refresh_outlined;
      case 'reminders':
        return Icons.notifications_active_outlined;
      default:
        return Icons.analytics_outlined;
    }
  }

  Widget _buildStatsWidget() {
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
                "Prescriptions",
                counters["quotations"].toString(),
                Color(0xFF4675C0),
                () {
                  Navigator.pushNamed(context, '/patient_prescriptions_screen');
                },
              ),
              _buildStatCard(
                "Pending Orders",
                (counters["porders"] == null ||
                        counters["porders"].toString().isEmpty)
                    ? '0'
                    : counters["porders"].toString(),
                Color(0xFFEF4444),
                () {
                  Navigator.pushNamed(context, '/inporder_list_screen');
                },
              ),
              _buildStatCardWithText(
                "Total Sales",
                counters["totalAmount"].toString(),
                "KSH",
                Color(0xFF10B981),
                () {
                  Navigator.pushNamed(context, '/patient_payments_screen');
                },
              ),
              _buildStatCard(
                "Delivered",
                counters["delivered"].toString(),
                Color(0xFF8B5CF6),
                () {
                  Navigator.pushNamed(context, '/dpatient_order_list_screen');
                },
              ),
              _buildStatCard(
                "Refill",
                counters["refill"].toString(),
                Color(0xFFF59E0B),
                () {
                  if (counters["refill"] == 0 || counters["refill"] == "0") {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("No Refill Available"),
                        backgroundColor: Color(0xFFF59E0B),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    Navigator.pushNamed(context, '/dpatient_order_list_screen');
                  }
                },
              ),
              _buildStatCard(
                "Reminders",
                counters["reminder"].toString(),
                Color(0xFFEC4899),
                () async {
                  final Uri calendarUri =
                      Uri.parse("content://com.android.calendar/time/");
                  if (await canLaunchUrl(calendarUri)) {
                    await launchUrl(calendarUri);
                  } else {
                    print("Could not open calendar");
                  }
                },
              ),
            ],
          ),
        ],
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
                  Navigator.pushNamed(context, '/order_list_screen');
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
                            color: order["color"] as Color,
                            shape: BoxShape.circle,
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
        "route": "/quotationrequest_patient_screen",
        "color": Color(0xFF4675C0),
      },
      {
        "title": "Orders",
        "icon": Icons.shopping_bag_outlined,
        "route": "/order_list_screen",
        "color": Color(0xFF10B981),
      },
      {
        "title": "Pharmacy",
        "icon": Icons.local_pharmacy_outlined,
        "route": "/dpharmacy_list",
        "color": Color(0xFFF59E0B),
      },
      {
        "title": "Doctors",
        "icon": Icons.medical_services_outlined,
        "route": "/ddoctor_list",
        "color": Color(0xFF8B5CF6),
      },
      {
        "title": "Reports",
        "icon": Icons.assessment_outlined,
        "route": "/reports",
        "color": Color(0xFFEF4444),
      },
      {
        "title": "Pending",
        "icon": Icons.pending_outlined,
        "route": "/inporder_list_screen",
        "color": Color(0xFFEC4899),
      },
      {
        "title": "Messages",
        "icon": Icons.message_outlined,
        "route": "/notification",
        "color": Color(0xFF06B6D4),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Services",
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 16.0),
        GridView.builder(
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
                        fontSize: 12.0,
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
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          Text(
            "QuikDawa",
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4675C0),
              letterSpacing: 1.0,
            ),
          ),
          SizedBox(height: 8.0),
          Text(
            "Copyright © QuikDawa 2024. All Rights Reserved.",
            style: TextStyle(
              fontSize: 14.0,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
