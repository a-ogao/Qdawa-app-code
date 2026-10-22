import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../core/app_export.dart';
import '../../../core/config/app_config.dart';
import '../../../widgets/pii_deidentified_badge.dart';
import 'widgets/otc_list_widget.dart';
import '../../pharmacy/nav_bar/navbar_widget.dart';

class PharmacySymptomsScreen extends StatefulWidget {
  @override
  _PharmacySymptomsScreenState createState() => _PharmacySymptomsScreenState();
}

class _PharmacySymptomsScreenState extends State<PharmacySymptomsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController searchController = TextEditingController();

  List<dynamic> quotations = []; // Store API data
  List<dynamic> filteredQuotations = [];
  Map<String, dynamic> counters = {
    "quotations": 0,
    "orders": 0,
    "totalAmount": "KSH 0",
    "delivered": 0,
    "notification": 0,
  };
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    fetchQuotations(); // Call API when screen loads
    searchController.addListener(_filterQuotations);
    fetchCounters();
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
        Uri.parse(AppConfig.buildApiUrl('pharmacycounters')),
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

  Future<void> fetchQuotations() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userDataString = prefs.getString('userData');

      if (userDataString == null) {
        print("[OTC Requests] User data is not available");
        return;
      }

      final Map<String, dynamic> userData = json.decode(userDataString);
      final int? userId = userData['id'];

      if (userId == null) {
        print("[OTC Requests] User ID is not available in userData");
        return;
      }

      final apiUrl = AppConfig.buildApiUrl('get_pharmacy_symrequest');
      print("[OTC Requests] Fetching from get_pharmacy_symrequest, pharmacy_id=$userId");

      final response = await http.post(
        Uri.parse(apiUrl),
        body: {'pharmacy_id': userId.toString()},
      );

      print("[OTC Requests] API response: status=${response.statusCode}, body=${response.body}");

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);

        if (responseData is Map &&
            responseData.containsKey("success") &&
            responseData["success"] == false) {
          setState(() {
            quotations = [];
            filteredQuotations = [];
            isLoading = false;
          });
          print("[OTC Requests] API returned success=false");
          return;
        }

        if (responseData is Map && responseData.containsKey("quotations")) {
          final list = responseData["quotations"] as List;
          print("[OTC Requests] Received ${list.length} OTC request(s)");
          setState(() {
            quotations = list;
            filteredQuotations = list;
            isLoading = false;
          });
        } else {
          setState(() {
            quotations = [];
            filteredQuotations = [];
            isLoading = false;
          });
          print("[OTC Requests] Unexpected API response format (no 'quotations' key)");
        }
      } else {
        print("[OTC Requests] Failed to load data, status=${response.statusCode}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      print("[OTC Requests] Error fetching data: $error");
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterQuotations() {
    final query = searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        filteredQuotations = quotations;
      });
      return;
    }
    setState(() {
      filteredQuotations = quotations.where((quotation) {
        final requestId = quotation['qre_request_id']?.toString() ?? '';

        return requestId.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: appTheme.whiteA700,
      appBar: AppBar(
        title: Text(
          "OTC Requests",
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none, // Allow badge to overflow
            children: [
              GestureDetector(
                onTap: () {
                  if (counters["notification"]?.toString() != "0" &&
                      counters["notification"]?.toString().isNotEmpty == true) {
                    Navigator.pushNamed(
                      context,
                      '/pharmacy_notification', // Replace with your route
                    );
                  } // // Replace with your route
                },
                child: Container(
                  margin: EdgeInsets.only(right: 8.0),
                  height: 36.0,
                  width: 36.0,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
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
                      right: 0, // Align to the right edge
                      top: -6, // Move badge above the icon
                      child: Container(
                        padding: EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white,
                              width: 1.5), // White border for better visibility
                        ),
                        constraints: BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          counters["notification"]
                              .toString(), // Replace with dynamic count
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
        backgroundColor: theme.colorScheme.primary,
      ),
      drawer: Navbar(scaffoldKey: _scaffoldKey), // ✅ Add this line
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
              _buildEnhancedSearchSection(),
              SizedBox(height: 20),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    setState(() => isLoading = true);
                    await fetchQuotations();
                  },
                  child: isLoading
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: 300,
                            child: _buildLoadingState(),
                          ),
                        )
                      : filteredQuotations.isEmpty
                          ? SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: SizedBox(
                                height: 300,
                                child: _buildEmptyState(),
                              ),
                            )
                          : _buildEnhancedOTCList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedSearchSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: Colors.grey[600],
              size: 20,
            ),
            SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Search OTC requests...",
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 16,
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
            if (searchController.text.isNotEmpty)
              IconButton(
                icon: Icon(Icons.clear, color: Colors.grey[600]),
                onPressed: () {
                  searchController.clear();
                  _filterQuotations();
                },
              ),
          ],
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
            'Loading OTC requests...',
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
              Icons.medical_services_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No OTC requests found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search criteria',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedOTCList() {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      separatorBuilder: (context, index) => SizedBox(height: 12),
      itemCount: filteredQuotations.length,
      itemBuilder: (context, index) {
        final item = filteredQuotations[index];

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
            padding: EdgeInsets.symmetric(vertical: 8),
            child: OTClistWidget(
              name:
                  "${item["pat_first_name"] ?? "Unknown"} ${item["qre_request_id"] ?? ""}",
              location: item["adr_address_1"] ?? "No address provided",
              phone: item["usr_mobile_number"] ?? "No phone",
              price: item["quo_total_amount"]?.toString() ?? "0.0",
              status: item["qre_quotation_status"] ?? "Pending",
              id: item["id"] ?? 0,
              requestCode:
                  (item["qre_request_id"] ?? "").toString(), // front-end only
              isDeidentified: PiiDeidentifiedBadge.isDeidentified(
                item['pii_deidentified'],
              ),
            ),
          ),
        );
      },
    );
  }
}
