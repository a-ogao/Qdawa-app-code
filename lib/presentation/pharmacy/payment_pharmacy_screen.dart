import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_config.dart';
import '../pharmacy/nav_bar/navbar_widget.dart';

const Color _primaryColor = Color(0xFF4675C0);

class PaymentListScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  State<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends State<PaymentListScreen> {
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> payments = [];
  List<Map<String, dynamic>> filteredPayments = [];

  bool isLoading = true;
  String? errorMessage;

  double totalAmount = 0;
  String currency = 'KSH';
  int totalOrders = 0;

  @override
  void initState() {
    super.initState();
    _fetchPayments();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPayments({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userDataString = prefs.getString('userData');

      if (userDataString == null) {
        setState(() {
          errorMessage = "User not found. Please sign in again.";
          isLoading = false;
        });
        return;
      }

      final Map<String, dynamic> userData = json.decode(userDataString);
      final int? userId = userData['id'];

      if (userId == null) {
        setState(() {
          errorMessage = "User ID missing.";
          isLoading = false;
        });
        return;
      }

      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('get_payments')),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'usr_id': userId.toString()},
      );

      debugPrint("📡 pharmacy get_payments request: usr_id=$userId");
      debugPrint(
          "📨 pharmacy get_payments response [${response.statusCode}]: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final List<dynamic> data = body['data'] ?? [];
          final List<Map<String, dynamic>> list = data
              .map((item) => Map<String, dynamic>.from(item))
              .toList(growable: false);

          // Calculate total amount and orders
          // Note: Total amount is calculated from ord_total_amount only (excluding delivery charge)
          double calculatedTotal = 0;
          for (var payment in list) {
            final amount = (payment['ord_total_amount'] ?? 0).toString();
            try {
              calculatedTotal += (double.tryParse(amount) ?? 0);
            } catch (e) {
              debugPrint("Error parsing amount: $e");
            }
          }

          setState(() {
            payments = list;
            filteredPayments = List.from(list);
            totalAmount = calculatedTotal;
            totalOrders = list.length;
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage =
                body['message']?.toString() ?? "Unable to load payments.";
            payments = [];
            filteredPayments = [];
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage =
              "Server error (${response.statusCode}). Please try again.";
          payments = [];
          filteredPayments = [];
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching payments: $e");
      setState(() {
        errorMessage = "Something went wrong. Please try again.";
        isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        filteredPayments = List.from(payments);
      });
      return;
    }

    setState(() {
      filteredPayments = payments.where((payment) {
        final requestId = payment['quo_req_id']?.toString().toLowerCase() ?? 
            payment['id']?.toString().toLowerCase() ?? '';
        final patientName =
            payment['usr_username']?.toString().toLowerCase() ?? '';
        final status = payment['ord_order_status']?.toString().toLowerCase() ??
            '';
        return requestId.contains(query) ||
            patientName.contains(query) ||
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
          "Total Sales",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: _primaryColor,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () => widget._scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: Navbar(scaffoldKey: widget._scaffoldKey),
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
              SizedBox(height: 12),
              _buildSummaryCard(),
              SizedBox(height: 16),
              _buildSearchBar(),
              SizedBox(height: 16),
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : errorMessage != null
                        ? _buildErrorState()
                        : filteredPayments.isEmpty
                            ? _buildEmptyState()
                            : _buildPaymentsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Summary",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  title: "Total Amount",
                  value: "$currency ${totalAmount.toStringAsFixed(2)}",
                  accentColor: _primaryColor,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _SummaryTile(
                  title: "Total Orders",
                  value: totalOrders.toString(),
                  accentColor: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
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
                hintText: 'Search by Request ID, Patient, or Status',
                border: InputBorder.none,
              ),
            ),
          ),
          if (searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, color: Colors.grey[600]),
              onPressed: () => searchController.clear(),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentsList() {
    return RefreshIndicator(
      color: _primaryColor,
      onRefresh: () => _fetchPayments(showLoader: false),
      child: ListView.separated(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: filteredPayments.length,
        separatorBuilder: (_, __) => SizedBox(height: 12),
        itemBuilder: (context, index) {
          final payment = filteredPayments[index];
          final requestId = payment['quo_req_id']?.toString() ?? 
              payment['id']?.toString() ?? '';
          final patientName = payment['usr_username']?.toString() ?? '';
          // Display only order amount (without delivery charge)
          final totalAmountValue = (double.tryParse(
                      payment['ord_total_amount']?.toString() ?? '0') ??
                  0);
          final status = payment['ord_order_status']?.toString() ?? '';
          final date = payment['ord_created_dt']?.toString() ??
              payment['created_at']?.toString() ??
              '';

          return _PaymentCard(
            requestId: _formatRequestId(requestId),
            amountLabel: "$currency ${totalAmountValue.toStringAsFixed(2)}",
            statusLabel: status.isNotEmpty ? status.toUpperCase() : 'PENDING',
            dateLabel: date,
            patientName: patientName,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long,
              size: 48, color: Colors.grey.withOpacity(0.5)),
          SizedBox(height: 12),
          Text(
            "No payments found",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "Completed orders will show up here.",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          SizedBox(height: 12),
          Text(
            errorMessage ?? "Unable to load payments.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
            ),
            onPressed: () => _fetchPayments(),
            child: Text("Retry"),
          ),
        ],
      ),
    );
  }

  String _formatRequestId(dynamic raw) {
    final value = raw?.toString() ?? '';
    if (value.isEmpty) return '';
    return value.startsWith('#') ? value : '#$value';
  }
}

class _SummaryTile extends StatelessWidget {
  final String title;
  final String value;
  final Color accentColor;

  const _SummaryTile({
    required this.title,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final String requestId;
  final String amountLabel;
  final String statusLabel;
  final String dateLabel;
  final String patientName;

  const _PaymentCard({
    required this.requestId,
    required this.amountLabel,
    required this.statusLabel,
    required this.dateLabel,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                if (patientName.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.person,
                          size: 16, color: Colors.grey[600]),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          patientName,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
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
    );
  }

  static String _formatDate(String date) {
    try {
      DateTime dt =
          DateTime.parse(date.contains('T') ? date : date.replaceAll(' ', 'T'));
      return "${dt.day.toString().padLeft(2, '0')}/"
          "${dt.month.toString().padLeft(2, '0')}/"
          "${dt.year}";
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
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _statusColor(String label) {
    final value = label.toLowerCase();
    if (value.contains('deliver')) return Colors.green;
    if (value.contains('dispatch')) return Colors.orange;
    if (value.contains('ready')) return Colors.blue;
    if (value.contains('cancel')) return Colors.red;
    if (value.contains('pending')) return Colors.orange;
    return Colors.grey;
  }
}
