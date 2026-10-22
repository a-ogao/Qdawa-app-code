import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import 'dart:convert';
import '../../core/app_export.dart';
import '../invoice_screen/invoice_screen.dart';
import '../reminder_screen.dart';
import '../feedback_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/pii_deidentified_badge.dart';

class OrderTrackStatusScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackStatusScreen({Key? key, required this.orderId})
      : super(key: key);

  @override
  State<OrderTrackStatusScreen> createState() => _OrderTrackStatusScreenState();
}

class _OrderTrackStatusScreenState extends State<OrderTrackStatusScreen> {
  List<Map<String, dynamic>> orderStatuses = [];
  List<Map<String, dynamic>> orders = [];

  bool isLoading = true;
  String currentStatus = '';
  String ord_order_type = '';
  String feedbackstatus = '';
  String qreRequestId = ''; // Quotation request ID for display
  double totalAmount = 0.0;
  double delivery = 0.0;
  double couponDiscount = 0.0;
  double originalAmount = 0.0;
  String couponCode = '';
  double rating = 0.0;
  String otp = "";
  TextEditingController toponeController = TextEditingController();
  String pharmacy = "Malibu Pharmacy Limited"; // Default pharmacy name
  bool pharmacyDeidentified = false;
  TextEditingController feedbackController =
      TextEditingController(); // Feedback field controller
  double userRating = 0.0; // Stores user rating

  @override
  void initState() {
    super.initState();
    fetchOrderTrackingData(widget.orderId);
  }

  Future<void> fetchOrderTrackingData(String orderId) async {
    final url = Uri.parse(AppConfig.buildApiUrl('order_view'));
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userDataString = prefs.getString('userData');
      final Map<String, dynamic>? userData =
          userDataString != null ? json.decode(userDataString) : null;
      final int? userId = userData?['id'];

      final response = await http.post(url, body: {
        'order_id': orderId,
        if (userId != null) 'usr_id': userId.toString(),
      });
      //print(response.body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'myordertype', data['order']['ord_order_type'].toString());
        await prefs.setString('myorderid', widget.orderId.toString());

        setState(() {
          orders = List<Map<String, dynamic>>.from(data['items'] ?? []);
          orderStatuses = data['order'] != null ? [data['order']] : [];
          // print(orderStatuses);
          // print(orders);
          currentStatus = data['order']['ord_order_status'] ?? '';
          ord_order_type = data['order']['ord_order_type'] ?? '';
          pharmacy = data['order']['pha_first_name'] ?? '';
          pharmacyDeidentified = PiiDeidentifiedBadge.isDeidentified(
            data['order']['pii_deidentified'],
          );
          qreRequestId = data['order']['qre_request_id']?.toString() ?? '';
          otp = data['del_delivery_otp'] ?? '';
          // currentStatus = orderStatuses.isNotEmpty
          //   ? orderStatuses.last['ord_order_status'] ?? ''
          //   : '';
          //print(currentStatus);
          totalAmount =
              double.tryParse(data['order']['ord_total_amount'].toString()) ??
                  0.0;
          delivery = double.tryParse(
                  data['order']['ord_delivery_charge'].toString()) ??
              0.0;
          couponDiscount = double.tryParse(
                  data['order']['ord_coupon_discount']?.toString() ?? '0') ??
              0.0;
          originalAmount = double.tryParse(
                  data['order']['ord_original_amount']?.toString() ?? '') ??
              (couponDiscount > 0 ? totalAmount + couponDiscount : totalAmount);
          couponCode = data['order']['ord_coupon_code']?.toString() ?? '';
          feedbackstatus = data['order']['feedback_status'].toString() ?? '';
          //print(feedbackstatus);
          rating =
              double.tryParse(data['order']['pharmacy_rating'].toString()) ??
                  0.0;
          isLoading = false;
        });
      } else {
        print('Failed to load order statuses: ${response.body}');
      }
    } catch (e) {
      print('Error occurred: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          qreRequestId.isNotEmpty
              ? "Track Order #$qreRequestId"
              : "Track Order",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
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
          child: isLoading
              ? _buildLoadingState()
              : SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 8),
                        // Pharmacy Info Card
                        _buildPharmacyCard(),
                        SizedBox(height: 16),
                        // Order Items Card
                        _buildDefaultSection(),
                        SizedBox(height: 16),
                        // Order Tracking Header
                        _buildTrackingHeader(),
                        SizedBox(height: 20),
                        // Timeline
                        _buildTimelineWithLabels(),
                        SizedBox(height: 16),
                        // OTP Card
                        if (currentStatus.toLowerCase() == 'pickedup' ||
                            currentStatus.toLowerCase() == 'dispatched')
                          _buildOTPCard(),
                        SizedBox(height: 16),
                        // Action Buttons for Delivered Status
                        if (currentStatus.toLowerCase() == 'delivered')
                          _buildActionButtons(),
                        // Rating Section
                        if (feedbackstatus == '1') _buildRatingSection(),
                        SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
        ),
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
            'Loading order details...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPharmacyCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0XFF4675C0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.local_pharmacy,
                color: Color(0XFF4675C0),
                size: 28,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Pharmacy",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    pharmacy.isNotEmpty ? pharmacy : 'Malibu Pharmacy Limited',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (pharmacyDeidentified) ...[
                    SizedBox(height: 6),
                    const PiiDeidentifiedBadge(compact: true),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0XFF4675C0), Color(0XFF5585D0)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0XFF4675C0).withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping, color: Colors.white, size: 24),
            SizedBox(width: 12),
            Text(
              "Order Tracking",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOTPCard() {
    return Container(
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
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.lock_outline, color: Colors.white, size: 32),
            SizedBox(height: 12),
            Text(
              "Share OTP with delivery person",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                otp,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                  letterSpacing: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildModernButton(
          text: "View Invoice",
          icon: Icons.receipt_long,
          color: Color(0XFF4675C0),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InvoiceScreen(orderId: widget.orderId),
              ),
            );
          },
        ),
        SizedBox(height: 12),
        _buildModernButton(
          text: "Set Reminder",
          icon: Icons.notifications_active,
          color: Colors.purple,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReminderScreen(orderId: widget.orderId),
              ),
            );
          },
        ),
        if (feedbackstatus == '0') ...[
          SizedBox(height: 12),
          _buildModernButton(
            text: "Write Review",
            icon: Icons.rate_review,
            color: Colors.green,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FeedbackScreen(),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildModernButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                SizedBox(width: 12),
                Text(
                  text,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  "Your Rating",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    index < (rating ?? 0) ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultSection() {
    return orders.isEmpty
        ? Container(
            padding: EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                "No orders found",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
          )
        : Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header with icon
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0XFF4675C0).withOpacity(0.1),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.medication,
                        color: Color(0XFF4675C0),
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Text(
                        "Order Items",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0XFF4675C0),
                        ),
                      ),
                    ],
                  ),
                ),
                // Table Header
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          "Medicine",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          "Dosage",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          "Qty",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          "Price",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          "Amount",
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Order Items List
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orders.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Colors.grey[200],
                  ),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              order['oit_item_name'] ?? "Unknown",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              order['oit_item_dosage'] != null
                                  ? order['oit_item_dosage'].toString()
                                  : "0",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              order['oit_qty'].toString(),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              order['oit_amount_per_unit'].toString(),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              "${order['oit_amount']}",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // Totals Section
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (ord_order_type == 'delivery') ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Delivery Charges",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              "KSH ${delivery.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Divider(height: 1, color: Colors.grey[300]),
                        SizedBox(height: 12),
                      ],
                      if (couponDiscount > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Coupon ($couponCode)",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              "- KSH ${couponDiscount.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (originalAmount > totalAmount) ...[
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Subtotal",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                "KSH ${originalAmount.toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                        SizedBox(height: 12),
                        Divider(height: 1, color: Colors.grey[300]),
                        SizedBox(height: 12),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Total Amount",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            "KSH ${totalAmount.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0XFF4675C0),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Timeline Section
  Widget _buildTimelineWithLabels() {
    List<Map<String, dynamic>> filteredStatuses = [];
    List<String> statusSequence = [];
    if (ord_order_type == 'delivery') {
      statusSequence = ['pending', 'ready', 'dispatched', 'delivered'];
    } else {
      statusSequence = ['pending', 'ready', 'pickedup'];
    }

    // Normalize `currentStatus`
    String normalizedCurrentStatus = currentStatus.toLowerCase().trim();
    int currentStatusIndex = statusSequence.indexOf(normalizedCurrentStatus);

    if (currentStatusIndex != -1) {
      for (int i = 0; i <= currentStatusIndex; i++) {
        String targetStatus = statusSequence[i];

        var statusesForCurrentStep = orderStatuses
            .where((status) =>
                (status['ord_order_status']?.toString().toLowerCase().trim() ??
                    '') ==
                targetStatus)
            .toList();

        if (statusesForCurrentStep.isEmpty) {
          filteredStatuses.add({
            'ord_order_status': targetStatus,
            'status': 'No data available',
            'ord_modified_dt': ''
          });
        } else {
          filteredStatuses.addAll(statusesForCurrentStep);
        }
      }
    } else {
      filteredStatuses = orderStatuses;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: filteredStatuses.length,
        itemBuilder: (context, index) {
          final status = filteredStatuses[index];
          final isLast = index == filteredStatuses.length - 1;
          final statusColor = _getStatusColor(status['ord_order_status'] ?? '');

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline indicator column
              Column(
                children: [
                  // Status dot
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: statusColor,
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  // Connecting line
                  if (!isLast)
                    Container(
                      width: 3,
                      height: 60,
                      color: Colors.grey[300],
                      margin: EdgeInsets.symmetric(vertical: 4),
                    ),
                ],
              ),
              SizedBox(width: 16),
              // Status info
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _capitalize(status['ord_order_status'] ?? ''),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      if (status['ord_modified_dt'] != null &&
                          status['ord_modified_dt'].toString().isNotEmpty)
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: statusColor,
                              ),
                              SizedBox(width: 4),
                              Text(
                                status['ord_modified_dt'].toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Status Color Mapping (Show all statuses progressively)
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.blue; // Primary color
      case 'ready':
        return Colors.orange; // Secondary status color
      case 'dispatched':
        return Colors.purple; // Status colors in sequence
      case 'pickedup':
        return Colors.red;
      case 'delivered':
        return Colors.green; // Final status
      default:
        return appTheme.gray30001;
    }
  }
}
