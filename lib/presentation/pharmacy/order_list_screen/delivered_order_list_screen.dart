import 'package:flutter/material.dart';
import '../../pharmacy/nav_bar/navbar_widget.dart'; // Import the Navbar widget
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'widgets/order_list_one_item_widget.dart';
import '../../../core/config/app_config.dart';

class dPharmacyOrderListScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  _OrderListScreenState createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<dPharmacyOrderListScreen> {
  final TextEditingController searchController = TextEditingController();
  List<dynamic> orders = [];
  List<dynamic> filteredOrders = []; // List to store filtered orders
  Map<String, dynamic> counters = {
    "quotations": 0,
    "orders": 0,
    "totalAmount": "KES 0",
    "delivered": 0,
    "notification": 0,
  };
  Future<void>? _ordersFuture; // Change from 'late' to nullable

  @override
  void initState() {
    super.initState();
    fetchCounters();
    _ordersFuture = fetchOrders(); // Assign the future at initialization
    searchController.addListener(_filterOrders);
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

  /// Fetch orders from API
  Future<void> fetchOrders() async {
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
        Uri.parse(AppConfig.buildApiUrl('get_pharmacy_dorder')),
        body: {'usr_id': userId.toString()},
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to fetch orders.");
      }

      final data = json.decode(response.body);
      setState(() {
        orders = data['orders'] ?? [];
        filteredOrders = List.from(orders); // Initialize filtered list
      });
    } catch (e) {
      print("Error fetching orders: $e");
    }
  }

  /// Search function for filtering orders by Order ID
  void _filterOrders() {
    final query = searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() {
        filteredOrders = List.from(orders);
      });
      return;
    }

    setState(() {
      filteredOrders = orders.where((order) {
        final orderId = order['id']?.toString().toLowerCase() ?? '';
        final pharmacyName =
            order['pha_first_name']?.toString().toLowerCase() ?? '';
        final ddate = order['ord_created_dt']?.toString().toLowerCase() ?? '';
        final amount =
            order['ord_total_amount']?.toString().toLowerCase() ?? '';

        return orderId.contains(query) ||
            pharmacyName.contains(query) ||
            amount.contains(query) ||
            ddate.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: widget._scaffoldKey,
      appBar: AppBar(
        title: Text(
          "Dispatched Order List",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            widget._scaffoldKey.currentState?.openDrawer();
          },
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
                  }
                  // Replace with your route
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
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      drawer: Navbar(scaffoldKey: widget._scaffoldKey), // Add Navbar here
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
              SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<void>(
                  future: _ordersFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (filteredOrders.isEmpty) {
                      return Center(child: Text('No orders found.'));
                    } else {
                      return _buildOrderList();
                    }
                  },
                ),
              ),
            ],
          ),
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
          hintText: "Search by ID, name, address, status...",
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

  /// Order List View
  Widget _buildOrderList() {
    if (filteredOrders.isEmpty) {
      return Center(child: Text('No orders found.'));
    }

    return RefreshIndicator(
      onRefresh: fetchOrders,
      color: Color(0XFF4675C0),
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: filteredOrders.length,
        separatorBuilder: (context, index) => SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = filteredOrders[index];

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
              child: OrderListOneItemWidget(
                id: order['id']?.toString() ?? '',
                customerName: order['qre_request_id']?.toString() ?? 'Unknown',
                amount: order['ord_total_amount']?.toString() ?? '0',
                username: order['usr_username']?.toString() ?? '',
                status: order['ord_order_status']?.toString() ?? '',
                order_type: order['ord_order_type']?.toString() ?? '',
                address: order['adr_address_1']?.toString() ?? '',
                quotationReqId: order['qre_request_id']?.toString() ?? '',
              ),
            ),
          );
        },
      ),
    );
  }
}
