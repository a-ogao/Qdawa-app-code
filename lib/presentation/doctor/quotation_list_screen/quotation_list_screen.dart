import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/app_export.dart';
import '../../../core/config/app_config.dart';
import 'widgets/quotation_list_item_widget.dart';
import '../../../widgets/app_version_label.dart';

class DQuotationListScreen extends StatefulWidget {
  @override
  _DQuotationListScreenState createState() => _DQuotationListScreenState();
}

class _DQuotationListScreenState extends State<DQuotationListScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController searchController = TextEditingController();
  List<dynamic> quotations = [];
  List<dynamic> filteredQuotations = [];
  bool isLoading = true;

  String? requestId; // To hold the Request ID

  @override
  void initState() {
    super.initState();
    searchController.addListener(_filterQuotations);
    // Fetch quotations after getting the request ID
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arguments = ModalRoute.of(context)!.settings.arguments as Map?;
      if (arguments != null && arguments['Requestid'] != null) {
        requestId = arguments['Requestid'].toString();
        _fetchQuotations(requestId!);
      } else {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    searchController.removeListener(_filterQuotations);
    searchController.dispose();
    super.dispose();
  }

  void _filterQuotations() {
    final query = searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        filteredQuotations = List<dynamic>.from(quotations);
        return;
      }
      filteredQuotations = quotations.where((q) {
        final pharmacy =
            (q['pha_first_name'] ?? '').toString().toLowerCase();
        final address =
            (q['pha_license_number'] ?? '').toString().toLowerCase();
        final contact =
            (q['pha_alt_phone_number'] ?? '').toString().toLowerCase();
        final amount =
            (q['quo_total_amount']?.toString() ?? '').toLowerCase();
        final id = (q['id']?.toString() ?? '').toLowerCase();
        final status =
            (q['qre_quotation_status']?.toString() ?? '').toLowerCase();
        return pharmacy.contains(query) ||
            address.contains(query) ||
            contact.contains(query) ||
            amount.contains(query) ||
            id.contains(query) ||
            status.contains(query);
      }).toList();
    });
  }

  Future<void> _fetchQuotations(String requestId) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userDataString = prefs.getString('userData');

      if (userDataString == null) {
        // Handle missing userData (e.g., redirect to login)
        print("User data is not available");
        return;
      }
      final Map<String, dynamic> userData = json.decode(userDataString);

      // Extract the 'id' field
      final int? userId = userData['id'];

      if (userId == null) {
        // Handle missing 'id' in userData
        print("User ID is not available in userData");
        return;
      }

      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('get_quotation_drequestid')),
        body: {
          'usr_id': userId.toString(),
          'request_id': requestId.toString()
        }, // Pass requestId here
      );
      //print(response.body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          quotations = data['quotations'] ?? [];
          filteredQuotations = List<dynamic>.from(quotations);
          isLoading = false;
        });
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
          "Quotation Request ID: ${requestId ?? 'N/A'}",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Color(0XFF4675C0),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
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
              _buildSearchSection(),
              SizedBox(height: 20),
              Expanded(
                child: isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0XFF4675C0),
                          ),
                        ),
                      )
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
        return QuotationListItemWidget(
          rid: quotation['id'].toString(),
          pharmacyName: quotation['pha_first_name'] ?? '',
          address: quotation['pha_license_number'] ?? '',
          contact: quotation['pha_alt_phone_number'] ?? '',
          reason: quotation['otcreject_reason'] ?? '',
          qstatus: quotation['qre_quotation_status'] ?? '',
        );
      },
    );
  }

  Widget _buildIcon(IconData icon, String message) {
    return GestureDetector(
      onTap: () => print(message),
      child: Container(
        margin: EdgeInsets.only(right: 8.0),
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: appTheme.lightBlue400,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: theme.colorScheme.primary),
            child: Text('QuickDawa',
                style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Dashboard'),
            onTap: () {
              Navigator.pushNamed(context,
                  '/doctordashboard_screen'); // Replace with your route
            },
          ),
          ListTile(
            leading: Icon(Icons.note),
            title: Text('Quotations'),
            onTap: () {
              Navigator.pushNamed(context,
                  '/quotationrequest_dpatient_screen'); // Replace with your route
            },
          ),
          ListTile(
            leading: Icon(Icons.card_travel),
            title: Text('Orders'),
            onTap: () {
              Navigator.pushNamed(
                  context, '/dorder_list_screen'); // Replace with your route
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () => Navigator.pop(context),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: AppVersionLabel(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
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
