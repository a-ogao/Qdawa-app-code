import 'package:flutter/material.dart';
import '../nav_bar/navbar_widget.dart'; // Import the Navbar widget
import '../../core/config/app_config.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

const Color _primaryColor = Color(0xFF4675C0);

class inpOrderListScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  _OrderListScreenState createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<inpOrderListScreen> {
  final TextEditingController searchController = TextEditingController();
  List<dynamic> orders = [];
  List<dynamic> pendingOrders = [];
  List<dynamic> filteredOrders = [];
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
        Uri.parse(AppConfig.buildApiUrl('usercounters')),
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

      final payload = {
        "usr_id": userId,
        "per_page": 100,
      };

      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('api/patient_prescriptions')),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to fetch orders.");
      }

      final Map<String, dynamic> data = json.decode(response.body);

      if (data['success'] != true) {
        throw Exception("Failed to fetch orders.");
      }

      setState(() {
        orders = (data['data'] ?? [])
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        pendingOrders = orders.where((order) {
          final status = order['status']?.toString().toLowerCase() ??
              order['status_label']?.toString().toLowerCase() ??
              '';
          return status == 'pending';
        }).toList();
        filteredOrders = List.from(pendingOrders); // Initialize filtered list
      });
    } catch (e) {
      print("Error fetching orders: $e");
    }
  }

  /// Function to filter orders based on Order ID or Pharmacy Name
  void _filterOrders() {
    final query = searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() {
        filteredOrders = List.from(pendingOrders); // Reset to filtered list
      });
      return;
    }

    setState(() {
      filteredOrders = pendingOrders.where((order) {
        final orderId = _orderDisplayId(order).toLowerCase();
        final orgName = (order['org_organization_name']?.toString() ??
                order['organization_name']?.toString() ??
                order['pharmacy_name']?.toString() ??
                '')
            .toLowerCase();
        final date = order['order_date']?.toString().toLowerCase() ??
            order['order_date_iso']?.toString().toLowerCase() ??
            '';
        final amount = order['amount']?.toString().toLowerCase() ??
            order['amount_label']?.toString().toLowerCase() ??
            '';
        final status = order['status_label']?.toString().toLowerCase() ??
            order['status']?.toString().toLowerCase() ??
            '';

        return orderId.contains(query) ||
            orgName.contains(query) ||
            amount.contains(query) ||
            date.contains(query) ||
            status.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: widget._scaffoldKey,
      appBar: AppBar(
        title: Text(
          "Pending Orders",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.menu,
            color: Colors.white,
          ),
          onPressed: () {
            widget._scaffoldKey.currentState?.openDrawer();
          },
        ),
        backgroundColor: _primaryColor,
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
                      '/notification', // Replace with your route
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
      ),
      drawer: Navbar(scaffoldKey: widget._scaffoldKey), // Add Navbar here
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _primaryColor.withOpacity(0.05),
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
                child: FutureBuilder(
                  future: _ordersFuture, // Use the stored future
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (filteredOrders.isEmpty) {
                      return _buildEmptyState();
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
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.grey[600]),
          SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search by Request ID, Pharmacy, Amount, Date",
                border: InputBorder.none,
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
    );
  }

  Widget _buildOrderList() {
    if (pendingOrders.isEmpty) {
      return _buildEmptyState();
    }
    return RefreshIndicator(
      color: _primaryColor,
      onRefresh: () => fetchOrders(),
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        physics: AlwaysScrollableScrollPhysics(),
        itemCount: filteredOrders.length,
        separatorBuilder: (_, __) => SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = filteredOrders[index];

          final orgName = order['org_organization_name']?.toString() ??
              order['organization_name']?.toString() ??
              order['pharmacy_name']?.toString() ??
              '';
          final phone = order['pharmacy_phone']?.toString() ??
              order['usr_mobile_number']?.toString() ??
              '';

          return _PendingOrderCard(
            requestId: _formatDisplayId(_orderDisplayId(order)),
            amountLabel: order['amount_label']?.toString() ??
                "${order['currency'] ?? 'KSH'} ${order['amount'] ?? '0'}",
            organization: orgName,
            phone: phone,
            dateLabel: order['order_date_iso']?.toString() ??
                order['order_date']?.toString() ??
                '',
            statusLabel: order['status_label']?.toString() ??
                (order['status']?.toString() ?? ''),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/order_track_status_screen',
                arguments: {
                  'orderId': order['order_id'] ?? order['id'],
                },
              );
            },
          );
        },
      ),
    );
  }

  String _orderDisplayId(Map<String, dynamic> order) {
    final requestId =
        order['request_id']?.toString().replaceAll('#', '').trim();
    if (requestId != null && requestId.isNotEmpty) {
      return requestId;
    }

    final quotationId =
        order['quotation_request_id']?.toString().replaceAll('#', '').trim();
    if (quotationId != null && quotationId.isNotEmpty) {
      return quotationId;
    }

    final qre = order['qre_request_id']?.toString().replaceAll('#', '').trim();
    if (qre != null && qre.isNotEmpty) {
      return qre;
    }

    return order['order_id']?.toString() ?? order['id']?.toString() ?? '';
  }

  String _formatDisplayId(String value) {
    if (value.isEmpty) return '';
    return value.startsWith('#') ? value : '#$value';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: Colors.grey.withOpacity(0.5),
          ),
          SizedBox(height: 12),
          Text(
            'No pending orders',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'New pending orders will appear here.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingOrderCard extends StatelessWidget {
  final String requestId;
  final String amountLabel;
  final String organization;
  final String phone;
  final String dateLabel;
  final String statusLabel;
  final VoidCallback onTap;

  const _PendingOrderCard({
    required this.requestId,
    required this.amountLabel,
    required this.organization,
    required this.phone,
    required this.dateLabel,
    required this.statusLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          requestId,
                          style: TextStyle(
                            color: _primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (dateLabel.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 14, color: Colors.grey[600]),
                        SizedBox(width: 6),
                        Text(
                          _formatDate(dateLabel),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.attach_money,
                          size: 20, color: Colors.green[600]),
                      SizedBox(width: 8),
                      Text(
                        amountLabel,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  if (organization.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.store_mall_directory,
                            size: 16, color: Colors.grey[600]),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            organization,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (phone.isNotEmpty) ...[
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.phone_outlined,
                            size: 16, color: Colors.grey[600]),
                        SizedBox(width: 8),
                        Text(
                          phone,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 8),
                  if (dateLabel.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 16, color: Colors.grey[600]),
                        SizedBox(width: 8),
                        Text(
                          _formatDate(dateLabel),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusChip(label: statusLabel),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(String date) {
    try {
      final dt =
          DateTime.parse(date.contains('T') ? date : date.replaceAll(' ', 'T'));
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
    } catch (_) {
      return date;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String label;

  const _StatusChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(label);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, size: 14, color: color),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static Color _statusColor(String raw) {
    final value = raw.toLowerCase();
    if (value.contains('deliver')) return Colors.green;
    if (value.contains('dispatch')) return Colors.orange;
    if (value.contains('ready')) return Colors.blue;
    if (value.contains('pending')) return Colors.orangeAccent;
    return Colors.grey;
  }
}
