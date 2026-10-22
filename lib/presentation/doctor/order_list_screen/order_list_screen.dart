import 'package:flutter/material.dart';
import '../../doctor/navbar/navbar_widget.dart'; // Import the Navbar widget
import '../../../core/config/app_config.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'widgets/order_list_one_item_widget.dart';

class DoctorOrderListScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  _OrderListScreenState createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<DoctorOrderListScreen> {
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
        Uri.parse(AppConfig.buildApiUrl('get_doctor_order')),
        body: {'usr_id': userId.toString()},
      );
      //print(response.body);
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
        final status =
            order['ord_order_status']?.toString().toLowerCase() ?? '';

        return orderId.contains(query) || status.contains(query);
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
          "Order List",
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
          onPressed: () {
            widget._scaffoldKey.currentState?.openDrawer();
          },
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
              "${filteredOrders.length} orders",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
              SizedBox(height: 20),
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

  /// Search Section Widget
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
                  hintText: 'Search orders...',
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

  /// Order List View
  Widget _buildOrderList() {
    if (filteredOrders.isEmpty) {
      return Center(child: Text('No orders found.'));
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 12),
      physics: BouncingScrollPhysics(),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];

        return OrderListOneItemWidget(
          id: order['id']?.toString() ?? '',
          customerName: order['qre_request_id']?.toString() ?? 'Unknown',
          username: order['usr_username']?.toString() ?? '',
          status: order['ord_order_status']?.toString() ?? '',
          order_type: order['ord_order_type']?.toString() ?? '',
          address: order['adr_address_1']?.toString() ?? '',
        );
      },
    );
  }
}
