import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../core/app_export.dart';
import '../../../core/config/app_config.dart';
import 'widgets/listravindersin_item_widget.dart';
import '../../pharmacy/nav_bar/navbar_widget.dart';

class QuotationRequestsPharmacyScreen extends StatefulWidget {
  @override
  _QuotationRequestsPharmacyScreenState createState() =>
      _QuotationRequestsPharmacyScreenState();
}

class _QuotationRequestsPharmacyScreenState
    extends State<QuotationRequestsPharmacyScreen> {
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
        Uri.parse(AppConfig.buildApiUrl('get_pharmacy_request')),
        body: {'pharmacy_id': userId.toString()},
      );

      // print(response.body);

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
          print("No quotations found");
          return;
        }

        if (responseData is Map && responseData.containsKey("quotations")) {
          setState(() {
            quotations = responseData["quotations"];
            filteredQuotations = quotations;
            isLoading = false;
          });
        } else {
          setState(() {
            quotations = [];
            filteredQuotations = [];
            isLoading = false;
          });
          print("Unexpected API response format");
        }
      } else {
        print("Failed to load data");
        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      print("Error fetching data: $error");
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
        final queryLower = query.toLowerCase();

        final requestId =
            quotation['qre_request_id']?.toString().toLowerCase() ?? '';
        final name = quotation['usr_username']?.toString().toLowerCase() ?? '';
        final amount =
            quotation['quo_total_amount']?.toString().toLowerCase() ?? '';
        final address =
            quotation['adr_address_1']?.toString().toLowerCase() ?? '';
        final phone =
            quotation['usr_mobile_number']?.toString().toLowerCase() ?? '';
        final quo_created_dt =
            quotation['quo_created_dt']?.toString().toLowerCase() ?? '';

        return requestId.contains(queryLower) ||
            name.contains(queryLower) ||
            amount.contains(queryLower) ||
            address.contains(queryLower) ||
            quo_created_dt.contains(queryLower) ||
            phone.contains(queryLower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Quotation Requests",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        elevation: 0,
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
                    color: Colors.white.withOpacity(0.2),
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
          Container(
            margin: EdgeInsets.only(right: 16),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${filteredQuotations.length} requests",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        backgroundColor: Color(0XFF4675C0),
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
              _buildEnhancedSearchSection(),
              SizedBox(height: 20),
              Expanded(
                child: isLoading
                    ? _buildLoadingState()
                    : filteredQuotations.isEmpty
                        ? _buildEmptyState()
                        : _buildEnhancedQuotationList(),
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
                  hintText: "Search requests...",
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
            'Loading requests...',
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
              Icons.description_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No quotation requests found',
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

  Widget _buildEnhancedQuotationList() {
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
            child: ListravindersinItemWidget(
              name: (item["pat_first_name"] ?? item["usr_username"] ?? "")
                  .toString()
                  .trim(),
              location: item["adr_address_1"] ?? "No address provided",
              phone: item["usr_mobile_number"] ?? "No phone",
              quodate: item["quo_created_dt"] ?? item["qre_created_dt"],
              price: item["quo_total_amount"]?.toString() ?? "0.0",
              status: item["qre_quotation_status"] ?? "Pending",
              id: item["id"] ?? "",
              quotationReqId: item["qre_request_id"]?.toString() ?? "",
            ),
          ),
        );
      },
    );
  }
}
