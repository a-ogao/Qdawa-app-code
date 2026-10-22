import 'package:flutter/material.dart';
import '../../pharmacy/nav_bar/navbar_widget.dart';
import '../../../core/config/app_config.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../widgets/pii_deidentified_badge.dart';
import 'widgets/order_list_one_item_widget.dart';

class PendingOrderListScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  _PendingOrderListScreenState createState() => _PendingOrderListScreenState();
}

class _PendingOrderListScreenState extends State<PendingOrderListScreen> {
  final TextEditingController searchController = TextEditingController();
  List<dynamic> orders = [];
  List<dynamic> filteredOrders = [];
  Map<String, dynamic> counters = {
    "quotations": 0,
    "orders": 0,
    "totalAmount": "KES 0",
    "delivered": 0,
    "notification": 0,
  };
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCounters();
    fetchOrders();
    searchController.addListener(_filterOrders);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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
      print("Error fetching counters: $e");
    }
  }

  /// Fetch orders from API and filter out delivered orders
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

      print("\n📦 === FETCHING PENDING ORDERS ===");
      print("User ID: $userId");
      print("API: ${AppConfig.buildApiUrl('get_pharmacy_order')}");

      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('get_pharmacy_order')),
        body: {'usr_id': userId.toString()},
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to fetch orders.");
      }

      final data = json.decode(response.body);
      final allOrders = data['orders'] ?? [];

      // Filter to show orders that are NOT delivered and NOT dispatched
      final pendingOrders = allOrders.where((order) {
        final status =
            order['ord_order_status']?.toString().toLowerCase() ?? '';
        return status != 'delivered' && status != 'dispatched';
      }).toList();

      print("Total orders from API: ${allOrders.length}");
      print(
          "Pending orders (not delivered & not dispatched): ${pendingOrders.length}");

      // Print status breakdown
      Map<String, int> statusCount = {};
      for (var order in allOrders) {
        final status = order['ord_order_status']?.toString() ?? 'unknown';
        statusCount[status] = (statusCount[status] ?? 0) + 1;
      }
      print("Status breakdown: $statusCount");
      print("=== END FETCHING ORDERS ===\n");

      setState(() {
        orders = pendingOrders;
        filteredOrders = List.from(pendingOrders);
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching orders: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Search function for filtering orders
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
        final queryLower = query.toLowerCase();

        final orderId = order['id']?.toString().toLowerCase() ?? '';
        final reqId = order['qre_request_id']?.toString().toLowerCase() ?? '';
        final name = order['usr_username']?.toString().toLowerCase() ?? '';
        final address = order['adr_address_1']?.toString().toLowerCase() ?? '';
        final amount =
            order['ord_total_amount']?.toString().toLowerCase() ?? '';
        final status =
            order['ord_order_status']?.toString().toLowerCase() ?? '';

        return orderId.contains(queryLower) ||
            reqId.contains(queryLower) ||
            name.contains(queryLower) ||
            address.contains(queryLower) ||
            amount.contains(queryLower) ||
            status.contains(queryLower);
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
          "Pending Orders",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Notification badge
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications, color: Colors.white),
                onPressed: () {
                  Navigator.pushNamed(context, '/pharmacy_notification_screen');
                },
              ),
              if (counters["notification"]?.toString() != "0" &&
                  counters["notification"]?.toString().isNotEmpty == true)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(4),
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
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // Menu icon
          IconButton(
            icon: Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              widget._scaffoldKey.currentState?.openDrawer();
            },
          ),
        ],
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
            _buildStatsCard(),
            SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? _buildLoadingState()
                  : filteredOrders.isEmpty
                      ? _buildEmptyState()
                      : _buildOrderList(),
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

  Widget _buildStatsCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[400]!, Colors.orange[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Pending Orders",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "${filteredOrders.length} orders",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.pending_actions,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
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
            "Loading pending orders...",
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
            Icons.check_circle_outline,
            size: 80,
            color: Colors.green[300],
          ),
          SizedBox(height: 16),
          Text(
            searchController.text.isEmpty
                ? "No Pending Orders"
                : "No orders match your search",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            searchController.text.isEmpty
                ? "All orders have been delivered!"
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

  Widget _buildOrderList() {
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
                isDeidentified: PiiDeidentifiedBadge.isDeidentified(
                  order['pii_deidentified'],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
