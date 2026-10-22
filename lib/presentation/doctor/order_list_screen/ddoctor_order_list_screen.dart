import 'package:flutter/material.dart';
import '../../doctor/navbar/navbar_widget.dart'; // Import the Navbar widget
import '../../../core/config/app_config.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../widgets/custom_search_view.dart';
import 'widgets/order_list_one_item_widget.dart';

class DDoctorOrderListScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  _OrderListScreenState createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<DDoctorOrderListScreen> {
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
        Uri.parse(AppConfig.buildApiUrl('get_doctor_dorder')),
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
        return orderId.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: widget._scaffoldKey,
      appBar: AppBar(
        title: Text(
          "Delivered Order List",
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
                  Navigator.pushNamed(context,
                      '/doctor_notification'); // Replace with your route
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
              Positioned(
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
              ),
            ],
          ),
        ],
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      drawer: Navbar(scaffoldKey: widget._scaffoldKey), // Add Navbar here
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchSection(),
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
    );
  }

  /// Search Section Widget
  Widget _buildSearchSection() {
    return Padding(
      padding: EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 38, // Slimmer height for the search bar
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Search by Order id and status",
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
                  hintStyle: TextStyle(fontSize: 12.0),
                ),
              ),
            ),
          ),
          Visibility(
            visible: searchController.text.isNotEmpty,
            child: IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                searchController.clear();
                _filterOrders();
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Order List View
  Widget _buildOrderList() {
    if (filteredOrders.isEmpty) {
      return Center(child: Text('No orders found.'));
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      physics: BouncingScrollPhysics(),
      itemCount: filteredOrders.length,
      separatorBuilder: (context, index) => Padding(
        padding: EdgeInsets.symmetric(vertical: 2),
      ),
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
