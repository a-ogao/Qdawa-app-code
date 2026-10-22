import 'package:flutter/material.dart';
import '../../pharmacy/nav_bar/navbar_widget.dart'; // Import the Navbar widget
import '../../../core/config/app_config.dart';
import '../../../widgets/pii_deidentified_badge.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'widgets/order_list_one_item_widget.dart';

class PharmacyOrderListScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  _OrderListScreenState createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<PharmacyOrderListScreen> {
  final TextEditingController searchController = TextEditingController();
  List<dynamic> orders = [];
  List<dynamic> filteredOrders = []; // List to store filtered orders
  String selectedStatusFilter = 'all'; // Status filter: 'all', 'pending', 'ready', 'dispatched', 'delivered', etc.
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
        Uri.parse(AppConfig.buildApiUrl('get_pharmacy_order')),
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
      _filterOrders(); // Apply current filters after fetching
    } catch (e) {
      print("Error fetching orders: $e");
    }
  }

  /// Search and filter function for orders
  void _filterOrders() {
    final query = searchController.text.trim().toLowerCase();

    setState(() {
      filteredOrders = orders.where((order) {
        // Status filter
        bool matchesStatus = true;
        if (selectedStatusFilter != 'all') {
          final orderStatus = order['ord_order_status']?.toString().toLowerCase() ?? '';
          matchesStatus = orderStatus == selectedStatusFilter.toLowerCase();
        }

        // Search filter
        bool matchesSearch = true;
        if (query.isNotEmpty) {
          final orderId = order['id']?.toString().toLowerCase() ?? '';
          final name = order['usr_username']?.toString().toLowerCase() ?? '';
          final address = order['adr_address_1']?.toString().toLowerCase() ?? '';
          final amount = order['ord_total_amount']?.toString().toLowerCase() ?? '';
          final status = order['ord_order_status']?.toString().toLowerCase() ?? '';

          matchesSearch = orderId.contains(query) ||
              name.contains(query) ||
              address.contains(query) ||
              amount.contains(query) ||
              status.contains(query);
        }

        return matchesStatus && matchesSearch;
      }).toList();
    });
  }

  /// Filter orders by status
  void _filterByStatus(String status) {
    setState(() {
      selectedStatusFilter = status;
    });
    _filterOrders();
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
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            widget._scaffoldKey.currentState?.openDrawer();
          },
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
              "${filteredOrders.length} orders",
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
              _buildEnhancedSearchSection(),
              SizedBox(height: 12),
              _buildStatusFilterChips(),
              SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<void>(
                  future: _ordersFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingState();
                    } else if (snapshot.hasError) {
                      return _buildErrorState(snapshot.error.toString());
                    } else if (filteredOrders.isEmpty) {
                      return _buildEmptyState();
                    } else {
                      return _buildEnhancedOrderList();
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
                  hintText: "Search orders...",
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
                  _filterOrders();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilterChips() {
    final statusFilters = [
      {'key': 'all', 'label': 'All'},
      {'key': 'pending', 'label': 'Preparing'},
      {'key': 'ready', 'label': 'Ready'},
      {'key': 'dispatched', 'label': 'Dispatched'},
      {'key': 'delivered', 'label': 'Delivered'},
      {'key': 'pickedup', 'label': 'Picked Up'},
      {'key': 'cancelled', 'label': 'Cancelled'},
    ];

    return Container(
      height: 50,
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: statusFilters.length,
        separatorBuilder: (context, index) => SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = statusFilters[index];
          final isSelected = selectedStatusFilter == filter['key'];
          
          return FilterChip(
            label: Text(
              filter['label']!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
            selected: isSelected,
            onSelected: (selected) {
              _filterByStatus(filter['key']!);
            },
            backgroundColor: Colors.white,
            selectedColor: Color(0XFF4675C0),
            checkmarkColor: Colors.white,
            side: BorderSide(
              color: isSelected ? Color(0XFF4675C0) : Colors.grey[300]!,
              width: 1.5,
            ),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            elevation: isSelected ? 2 : 0,
          );
        },
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
            'Loading orders...',
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

  Widget _buildErrorState(String error) {
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
              Icons.error_outline,
              size: 48,
              color: Colors.red[400],
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Error loading orders',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
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
              Icons.shopping_bag_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No orders found',
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

  Widget _buildEnhancedOrderList() {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      physics: BouncingScrollPhysics(),
      separatorBuilder: (context, index) => SizedBox(height: 12),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        final orderStatus = order['ord_order_status']?.toString() ?? '';

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.withOpacity(0.1),
              width: 1,
            ),
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
              status: orderStatus,
              order_type: order['ord_order_type']?.toString() ?? '',
              address: order['adr_address_1']?.toString() ?? '',
              quotationReqId: order['qre_request_id']?.toString() ?? '',
              isDeidentified: PiiDeidentifiedBadge.isDeidentified(
                order['pii_deidentified'],
              ),
              couponCode: order['ord_coupon_code']?.toString(),
              couponDiscount: order['ord_coupon_discount']?.toString(),
            ),
          ),
        );
      },
    );
  }
}
