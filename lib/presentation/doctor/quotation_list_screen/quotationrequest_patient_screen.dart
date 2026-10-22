import 'package:flutter/material.dart';
import '../navbar/navbar_widget.dart'; // Import the Navbar widget
import '../../../core/config/app_config.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'widgets/quotation_request_item_widget.dart';

class DQuotationRequestScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  _DQuotationRequestScreenState createState() =>
      _DQuotationRequestScreenState();
}

class _DQuotationRequestScreenState extends State<DQuotationRequestScreen> {
  final TextEditingController searchController = TextEditingController();
  List<dynamic> quotations = [];
  List<dynamic> filteredQuotations = [];
  bool isLoading = true;
  Map<String, dynamic> counters = {
    "quotations": 0,
    "orders": 0,
    "totalAmount": "KES 0",
    "delivered": 0,
    "notification": 0,
  };
  @override
  void initState() {
    super.initState();
    fetchCounters();

    _fetchQuotations();
    searchController.addListener(_filterQuotations);
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
      if (response.statusCode == 200) {
        setState(() {
          counters = json.decode(response.body);
        });
      }
    } catch (e) {
      print("Error fetching quotations: $e");
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
        Uri.parse(AppConfig.buildApiUrl('get_quotation_drequest')),
        body: {'usr_id': userId.toString()},
      );
      if (response.statusCode == 200) {
        // Print full API response in terminal
        print("\n" + "=" * 80);
        print("📋 FULL API RESPONSE FROM get_quotation_drequest");
        print("=" * 80);
        print(response.body);
        print("=" * 80 + "\n");

        final data = json.decode(response.body);

        // Debug: Print the API response structure
        print("\n📋 === API RESPONSE STRUCTURE DEBUG ===");
        print("Quotations count: ${(data['quotations'] ?? []).length}");

        // Debug: Print first quotation object to see available fields
        if ((data['quotations'] ?? []).isNotEmpty) {
          final firstQuotation = data['quotations'][0];
          print("\n🔍 First quotation object:");
          print(firstQuotation);
          print("\n📝 Available keys in quotation:");
          if (firstQuotation is Map) {
            firstQuotation.keys.forEach((key) {
              print("  - $key: ${firstQuotation[key]}");
            });
          }
          print("\n👤 Patient name fields check:");
          print("  - patient_name: ${firstQuotation['patient_name']}");
          print("  - pat_first_name: ${firstQuotation['pat_first_name']}");
          print("  - usr_first_name: ${firstQuotation['usr_first_name']}");
        }
        print("=== END API RESPONSE DEBUG ===\n");

        setState(() {
          quotations = data['quotations'] ?? [];
          filteredQuotations = quotations;
          isLoading = false;
        });
      } else {
        print("Failed to fetch quotations: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching quotations: $e");
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
      key: widget._scaffoldKey,
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Prescriptions",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Color(0XFF4675C0),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () => widget._scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${filteredQuotations.length} prescriptions",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      drawer: Navbar(scaffoldKey: widget._scaffoldKey),
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
              _buildSearchAndFilterRow(),
              SizedBox(height: 20),
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : filteredQuotations.isEmpty
                        ? Center(child: Text("No quotations available"))
                        : _buildQuotationList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuotationList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 12),
      itemCount: filteredQuotations.length,
      itemBuilder: (context, index) {
        final quotation = filteredQuotations[index];

        // Debug: Print patient name extraction for each item
        final patientNameValue = quotation['patient_name']?.toString() ??
            quotation['pat_first_name']?.toString() ??
            quotation['usr_first_name']?.toString() ??
            '';

        // Additional debug for first item
        if (index == 0) {
          print("\n🔍 Patient name extraction debug for first item:");
          print("  - quotation['patient_name']: ${quotation['patient_name']}");
          print(
              "  - quotation['pat_first_name']: ${quotation['pat_first_name']}");
          print(
              "  - quotation['usr_first_name']: ${quotation['usr_first_name']}");
          print("  - Final patientName: '$patientNameValue'");
        }

        return QuotationRequestItemWidget(
          Requestid: quotation['qre_request_id']?.toString() ?? '',
          requeststatus: quotation['qre_quotation_status']?.toString() ?? '',
          requestdate: quotation['qre_created_dt']?.toString() ?? '',
          qstatus: quotation['qre_quotation_status']?.toString() ?? '',
          patientName: patientNameValue,
        );
      },
    );
  }

  Widget _buildSearchAndFilterRow() {
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
              size: 24,
            ),
            SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search quotations...',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
            ),
            if (searchController.text.isNotEmpty)
              IconButton(
                icon: Icon(
                  Icons.clear,
                  color: Colors.grey[600],
                  size: 20,
                ),
                onPressed: () {
                  searchController.clear();
                },
              ),
          ],
        ),
      ),
    );
  }
}
