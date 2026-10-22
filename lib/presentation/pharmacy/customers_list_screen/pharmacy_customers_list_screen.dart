import 'package:flutter/material.dart';
import '../nav_bar/navbar_widget.dart';
import '../../../core/config/app_config.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class PharmacyCustomersListScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  _PharmacyCustomersListScreenState createState() =>
      _PharmacyCustomersListScreenState();
}

class _PharmacyCustomersListScreenState
    extends State<PharmacyCustomersListScreen> {
  final TextEditingController searchController = TextEditingController();
  List<dynamic> customers = [];
  List<dynamic> filteredCustomers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCustomers();
    searchController.addListener(_filterCustomers);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchCustomers() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userDataString = prefs.getString('userData');

      if (userDataString == null) {
        throw Exception("User data is missing.");
      }

      final Map<String, dynamic> userData = json.decode(userDataString);
      final int? userId = userData['id'];

      if (userId == null) {
        throw Exception("User ID is missing.");
      }

      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('get_pharmacy_customers')),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'usr_id': userId.toString()},
      );

      if (response.statusCode != 200) {
        throw Exception(
            "Failed to fetch customers. Status: ${response.statusCode}");
      }

      final data = json.decode(response.body);
      List<dynamic> customersList = [];

      if (data is Map) {
        if (data['data'] != null && data['data'] is List) {
          customersList = data['data'];
        } else if (data['success'] == true &&
            data['data'] != null &&
            data['data'] is List) {
          customersList = data['data'];
        } else if (data['customers'] != null && data['customers'] is List) {
          customersList = data['customers'];
        } else if (data.values.any((v) => v is List)) {
          customersList = data.values.firstWhere((v) => v is List) as List;
        }
      } else if (data is List) {
        customersList = data;
      }

      setState(() {
        customers = customersList;
        filteredCustomers = List.from(customersList);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _customerFirstName(Map<String, dynamic> customer) {
    return customer['first_name']?.toString().trim().isNotEmpty == true
        ? customer['first_name'].toString()
        : customer['patient_name']?.toString().trim().isNotEmpty == true
            ? customer['patient_name'].toString().split(' ').first
            : 'Unknown';
  }

  String _customerMaskedPhone(Map<String, dynamic> customer) {
    if (customer['masked_phone']?.toString().isNotEmpty == true) {
      return customer['masked_phone'].toString();
    }
    final phone = customer['usr_mobile_number']?.toString() ?? '';
    if (phone.length <= 7) return phone;
    return phone.substring(0, 3) +
        '*' * (phone.length - 7) +
        phone.substring(phone.length - 4);
  }

  void _filterCustomers() {
    final query = searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() {
        filteredCustomers = List.from(customers);
      });
      return;
    }

    setState(() {
      filteredCustomers = customers.where((customer) {
        final firstName = _customerFirstName(customer).toLowerCase();
        final maskedPhone = _customerMaskedPhone(customer).toLowerCase();
        final totalOrders =
            customer['total_orders']?.toString().toLowerCase() ?? '';

        return firstName.contains(query) ||
            maskedPhone.contains(query) ||
            totalOrders.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: widget._scaffoldKey,
      appBar: AppBar(
        title: Text(
          "Customers",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            widget._scaffoldKey.currentState?.openDrawer();
          },
        ),
        backgroundColor: Color(0XFF4675C0),
        elevation: 0,
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
        child: Column(
          children: [
            SizedBox(height: 16),
            _buildSearchSection(),
            SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? _buildLoadingState()
                  : filteredCustomers.isEmpty
                      ? _buildEmptyState()
                      : _buildCustomersList(),
            ),
          ],
        ),
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
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: "Search by name, phone, orders...",
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Color(0XFF4675C0)),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0XFF4675C0)),
          ),
          SizedBox(height: 16),
          Text(
            "Loading customers...",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
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
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[300],
          ),
          SizedBox(height: 16),
          Text(
            searchController.text.isEmpty
                ? "No Customers"
                : "No customers match your search",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            searchController.text.isEmpty
                ? "Customers will appear here once they place orders"
                : "Try a different search term",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomersList() {
    return RefreshIndicator(
      onRefresh: fetchCustomers,
      color: Color(0XFF4675C0),
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: filteredCustomers.length,
        separatorBuilder: (context, index) => SizedBox(height: 12),
        itemBuilder: (context, index) {
          final customer = filteredCustomers[index];
          final firstName = _customerFirstName(customer);
          final maskedPhone = _customerMaskedPhone(customer);

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 20,
                              color: Color(0XFF4675C0),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                firstName,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.purple.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shopping_bag,
                              size: 16,
                              color: Colors.purple,
                            ),
                            SizedBox(width: 6),
                            Text(
                              "${customer['total_orders'] ?? 0} Orders",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (maskedPhone.isNotEmpty) ...[
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 8),
                        Text(
                          maskedPhone,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
