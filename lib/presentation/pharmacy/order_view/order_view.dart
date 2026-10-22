import 'package:flutter/material.dart';
import 'package:timelines_plus/timelines_plus.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import 'dart:convert';
import '../../../core/app_export.dart';
import 'widgets/columnorderplac_item_widget.dart';
import 'widgets/columntime_item_widget.dart';
import 'widgets/columnview_item_widget.dart';
import '../../../theme/custom_button_style.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/custom_switch.dart';
import '../../../widgets/custom_text_form_field.dart';
import '../otp_screen/otp_screen.dart';
import '../order_list_screen/order_list_screen.dart';
import '../rider_choose_screen.dart';

class OrderView extends StatefulWidget {
  final String orderId;

  const OrderView({Key? key, required this.orderId}) : super(key: key);

  @override
  State<OrderView> createState() => _OrderTrackStatusScreenState();
}

class _OrderTrackStatusScreenState extends State<OrderView> {
  List<Map<String, dynamic>> orderStatuses = [];
  List<Map<String, dynamic>> orders = [];

  bool isLoading = true;
  String currentStatus = '';
  String ordpaymentmode = '';
  double totalAmount = 0.0;
  double delivery = 00;
  double couponDiscount = 0.0;
  double originalAmount = 0.0;
  String couponCode = '';
  double rating = 00;
  String transactionId = '';
  String transactionDate = '';
  String policyNumber = '';
  String insuranceName = '';
  String insuranceDOb = '';
  String insuranceDate = '';
  String mobileProvider = '';
  String transactionstatus = '';
  String guardian_name = '';
  String coupon_guid = '';
  String guardian_phone = '';
  String organization_name = '';
  String beneficiary_name = '';
  String beneficiary_dob = '';
  String status = '';
  String Paymode = '';
  TextEditingController toponeController = TextEditingController();
  String pharmacy = "Malibu Pharmacy Limited"; // Default pharmacy name

  @override
  void initState() {
    super.initState();
    //fetchOrderTrackingData(widget.orderId);
    fetchOrderTrackingData(widget.orderId);
  }

  Future<void> fetchOrderTrackingData(String orderId) async {
    final url = Uri.parse(AppConfig.buildApiUrl('order_view'));
    try {
      final response = await http.post(url, body: {'order_id': orderId});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          orders = List<Map<String, dynamic>>.from(data['items'] ?? []);
          orderStatuses = data['order'] != null ? [data['order']] : [];
          currentStatus = data['order']['ord_order_status'] ?? '';
          ordpaymentmode = data['order']['ord_payment_mode'] ?? '';

          print('Payment Mode from API: $ordpaymentmode'); // Debug log

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
          rating =
              double.tryParse(data['order']['pharmacy_rating'].toString()) ??
                  0.0;

          // Extract payment details from order_view response if available
          final normalizedMode = ordpaymentmode.toLowerCase().trim();
          if (normalizedMode == 'mobile_payment') {
            // Get transaction details from order object
            transactionId = data['order']['tra_transaction_id'] ?? '';

            // Check multiple possible field names for transaction status
            transactionstatus = data['order']['payment_status'] ??
                data['order']['tra_transaction_status'] ??
                data['order']['tra_payment_status'] ??
                '';

            Paymode = "M-Pesa";
            print(
                'From order_view - Payment Method: $Paymode, Transaction Status: $transactionstatus');
          } else if (normalizedMode == 'insurance') {
            Paymode = "Insurance";
          } else if (normalizedMode == 'coupon') {
            Paymode = "By Coupon";
          }

          // Still call fetchPaymentDetails as fallback for additional details
          fetchPaymentDetails(widget.orderId, ordpaymentmode);

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

  Future<void> _updateOrderStatus() async {
    String orderidd = '';
    if (orderStatuses.isNotEmpty) {
      orderidd = orderStatuses.first['ord_id'].toString();
    }
    try {
      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('update_ostatus')),
        body: {
          'order_id': orderidd,
          'ord_order_status': 'ready',
        },
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Order is ready for dispatch, and a delivery person has been successfully assigned and otp sent to rider!"),
              backgroundColor: Colors.green),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  PharmacyOrderListScreen()), // Navigate to Order List
        );
      } else {
        print("Failed to update order status.");
      }
    } catch (e) {
      print("Error updating order status: $e");
    }
  }

  Future<void> fetchPaymentDetails(String orderId, String paymentMode) async {
    final url = Uri.parse(AppConfig.buildApiUrl('get_payment_details'));

    try {
      final response = await http.post(url, body: {
        'order_id': orderId.toString(),
        'payment_mode': paymentMode.toString(),
      });

      print('Payment Details API Response: ${response.body}'); // Debug log
      print('Payment Mode Received: $paymentMode'); // Debug log

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Normalize payment mode for case-insensitive comparison
        final normalizedMode = paymentMode.toLowerCase().trim();

        setState(() {
          // Check if payment_data exists
          if (data['payment_data'] == null) {
            print('Warning: payment_data is null in API response');
            // Set default payment method even if payment_data is missing
            if (normalizedMode == 'mobile_payment') {
              Paymode = "M-Pesa";
            } else if (normalizedMode == 'insurance') {
              Paymode = "Insurance";
            } else if (normalizedMode == 'coupon') {
              Paymode = "By Coupon";
            }
            return;
          }

          if (normalizedMode == 'insurance') {
            policyNumber = data['payment_data']['ins_policy_number'] ?? '';
            insuranceName = data['payment_data']['ins_name'] ?? '';
            insuranceDOb = data['payment_data']['ins_dob'] ?? '';
            insuranceDate = data['payment_data']['ins_created_dt'] ?? '';
            Paymode = "Insurance";
          } else if (normalizedMode == 'mobile_payment') {
            // Only update if not already set from order_view
            if (transactionId.isEmpty) {
              transactionId = data['payment_data']['tra_transaction_id'] ?? '';
            }
            transactionDate = data['payment_data']['tra_created_dt'] ?? '';

            // Only update transaction status if not already set from order_view
            if (transactionstatus.isEmpty) {
              // Check multiple possible field names for transaction status
              // API returns tra_transaction_status and tra_payment_status as payment_status
              transactionstatus = data['payment_data']['payment_status'] ??
                  data['payment_data']['tra_transaction_status'] ??
                  data['payment_data']['tra_payment_status'] ??
                  '';
            }

            if (Paymode.isEmpty) {
              Paymode = "M-Pesa";
            }
            print(
                'From get_payment_details - Payment Method: $Paymode, Transaction Status: $transactionstatus');
          } else if (normalizedMode == 'coupon') {
            guardian_name = data['payment_data']['guardian_name'] ?? '';
            coupon_guid = data['payment_data']['coupon_guid'] ?? '';
            guardian_phone = data['payment_data']['guardian_phone'] ?? '';
            organization_name = data['payment_data']['organization_name'] ?? '';
            beneficiary_name = data['payment_data']['beneficiary_name'] ?? '';
            beneficiary_dob = data['payment_data']['beneficiary_dob'] ?? '';

            // Status from guardian_transactions.gdt_status (mapped to 'status' in response)
            status = data['payment_data']['status'] ??
                data['payment_data']['gdt_status'] ??
                '';

            Paymode = "By Coupon";
          } else {
            // Handle unknown payment modes
            print('Unknown payment mode: $paymentMode');
            Paymode = paymentMode.isNotEmpty ? paymentMode : "N/A";
          }
        });
      } else {
        print(
            'Failed to fetch payment details: ${response.statusCode} - ${response.body}');
        // Set default payment method even if API fails
        setState(() {
          final normalizedMode = paymentMode.toLowerCase().trim();
          if (normalizedMode == 'mobile_payment') {
            Paymode = "M-Pesa";
          } else if (normalizedMode == 'insurance') {
            Paymode = "Insurance";
          } else if (normalizedMode == 'coupon') {
            Paymode = "By Coupon";
          } else {
            Paymode = paymentMode.isNotEmpty ? paymentMode : "N/A";
          }
        });
      }
    } catch (e) {
      print('Error fetching payment details: $e');
      // Set default payment method even if there's an error
      setState(() {
        final normalizedMode = paymentMode.toLowerCase().trim();
        if (normalizedMode == 'mobile_payment') {
          Paymode = "M-Pesa";
        } else if (normalizedMode == 'insurance') {
          Paymode = "Insurance";
        } else if (normalizedMode == 'coupon') {
          Paymode = "By Coupon";
        } else {
          Paymode = paymentMode.isNotEmpty ? paymentMode : "N/A";
        }
      });
    }
  }

// ✅ Function to Show Confirmation Dialog
  void _showConfirmationDialog(BuildContext context) {
    int sorderid = 0;
    String sordertype = "";
    if (orderStatuses.isNotEmpty) {
      sorderid = orderStatuses.first['ord_id'];
      sordertype = orderStatuses.first['ord_order_type'].toString();
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Dispatch"),
          content: Text("Confirm order is ready for delivery"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                //  _updateOrderStatus();
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RiderListScreen(
                          orderidd: sorderid, ordertypee: sordertype),
                    ));
                // Call API to update status
              },
              child: Text("Yes,Ready to Dispatch"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildlastactivitySection() {
    String lastActivity = '';
    if (orderStatuses.isNotEmpty) {
      lastActivity = orderStatuses.first['ord_modified_dt'].toString();
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 16.h),
      padding: EdgeInsets.all(12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.h),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, spreadRadius: 1),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Last Activity:",
            style: TextStyle(fontSize: 12.h),
          ),
          Text(
            "$lastActivity",
            style: TextStyle(fontSize: 12.h, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16.h),
      padding: EdgeInsets.all(12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.h),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, spreadRadius: 1),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Order Rating",
            style: TextStyle(fontSize: 18.h, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 24.h,
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String requestid = '';
    String ordertype = '';
    int uorderid = 0;

    if (orderStatuses.isNotEmpty) {
      requestid = orderStatuses.first['qre_request_id'].toString();
      ordertype = orderStatuses.first['ord_order_type'].toString();
      uorderid = orderStatuses.first['ord_id'];
    }

    return Scaffold(
      backgroundColor: appTheme.whiteA700,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 1.h),
                    padding:
                        EdgeInsets.symmetric(horizontal: 14.h, vertical: 32.h),
                    decoration: AppDecoration.fillGray.copyWith(
                      borderRadius: BorderRadiusStyle.roundedBorder30,
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(bottom: 32.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: 45.h),

                          /// Top Request ID
                          Padding(
                            padding: EdgeInsets.only(right: 6.h),
                            child: CustomTextFormField(
                              controller: toponeController,
                              hintText:
                                  requestid.isNotEmpty ? '#$requestid' : '#1',
                              textInputAction: TextInputAction.done,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20.h,
                                vertical: 14.h,
                              ),
                              hintStyle: TextStyle(
                                color: Colors.white,
                                fontSize: 16.0,
                              ),
                              borderDecoration:
                                  TextFormFieldStyleHelper.fillPrimary,
                              fillColor: theme.colorScheme.primary,
                            ),
                          ),

                          _buildDefaultSection(),
                          SizedBox(height: 30.h),

                          _buildPaymentStatus(context),
                          _buildTransactionDetails(context),
                          _buildlastactivitySection(),

                          if (currentStatus == 'delivered')
                            _buildRatingSection(),
                          SizedBox(height: 24.h),

                          /// Conditional Buttons
                          if (ordertype == 'pickup' &&
                              currentStatus == 'pending')
                            CustomElevatedButton(
                              text: "Enter Pickup Code",
                              margin: EdgeInsets.only(left: 16.h, right: 14.h),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OtpInputScreen(
                                      orderidd: uorderid,
                                      ordertypee: ordertype,
                                    ),
                                  ),
                                );
                              },
                            ),

                          if (ordertype == 'delivery' &&
                              currentStatus == 'pending')
                            CustomElevatedButton(
                              text: "Ready To Dispatch",
                              margin: EdgeInsets.only(left: 16.h, right: 14.h),
                              rightIcon: Container(
                                margin: EdgeInsets.only(left: 15.h),
                                child: CustomImageView(
                                  imagePath:
                                      ImageConstant.imgArrowrightGray5003,
                                  height: 24.h,
                                  width: 24.h,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              onPressed: () {
                                _showConfirmationDialog(context);
                              },
                            ),

                          if (ordertype == 'delivery' &&
                              currentStatus == 'ready')
                            CustomElevatedButton(
                              text: "Dispatch",
                              margin: EdgeInsets.only(left: 16.h, right: 14.h),
                              rightIcon: Container(
                                margin: EdgeInsets.only(left: 15.h),
                                child: CustomImageView(
                                  imagePath:
                                      ImageConstant.imgArrowrightGray5003,
                                  height: 24.h,
                                  width: 24.h,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OtpInputScreen(
                                      orderidd: uorderid,
                                      ordertypee: ordertype,
                                    ),
                                  ),
                                );
                              },
                            ),

                          if (currentStatus == 'pickedup' ||
                              currentStatus == 'dispatched' ||
                              currentStatus == 'delivered')
                            Container(
                              padding: EdgeInsets.all(12.h),
                              child: Text(
                                currentStatus.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.h,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  /// Top Header Overlay
                  _buildTopHeader(),
                ],
              ),
      ),
    );
  }

  Widget _buildDefaultSection() {
    String ordertype = '';

    if (orderStatuses.isNotEmpty) {
      ordertype = orderStatuses.first['ord_order_type'].toString();
    }
    return orders.isEmpty
        ? const Center(child: Text("No Orders found."))
        : Container(
            width: double.infinity,
            margin: EdgeInsets.only(right: 6.h),
            padding: EdgeInsets.symmetric(vertical: 8.h),
            decoration: AppDecoration.fFFFFFDropShadow.copyWith(
              borderRadius: BorderRadiusStyle.roundedBorder5,
            ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.h),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          "Sr.",
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          "Item Name",
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          "Qty",
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          "Amount",
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.h),
                      child: Row(
                        children: [
                          Expanded(
                              flex: 1,
                              child: Text((index + 1).toString(),
                                  style: theme.textTheme.titleSmall)),
                          Expanded(
                              flex: 3,
                              child: Text(order['oit_item_name'] ?? "Unknown",
                                  style: theme.textTheme.titleSmall)),
                          Expanded(
                              flex: 1,
                              child: Text(order['oit_qty'].toString(),
                                  style: theme.textTheme.titleSmall)),
                          Expanded(
                              flex: 2,
                              child: Text(
                                "\ ${order['oit_amount']}",
                                style: theme.textTheme.titleSmall,
                                textAlign: TextAlign.right,
                              )),
                        ],
                      ),
                    );
                  },
                ),
                if (ordertype == 'delivery') const Divider(),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment
                              .topRight, // Ensures "Total" stays on the left
                          child: Text(
                            "Delivery Charges : ",
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "\KSH ${delivery.toStringAsFixed(2)}",
                          style: theme.textTheme.titleSmall,
                          textAlign: TextAlign.right, // Align text to the right
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                if (couponDiscount > 0) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Coupon ($couponCode) : ",
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.green[700],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "- KSH ${couponDiscount.toStringAsFixed(2)}",
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.green[700],
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (originalAmount > totalAmount)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Subtotal : ",
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              "KSH ${originalAmount.toStringAsFixed(2)}",
                              style: theme.textTheme.titleSmall,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Divider(),
                ],
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment
                              .topRight, // Ensures "Total" stays on the left
                          child: Text(
                            "Total : ",
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "\KSH ${totalAmount.toStringAsFixed(2)}",
                          style: theme.textTheme.titleSmall,
                          textAlign: TextAlign.right, // Align text to the right
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildTopHeader() {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        color: theme.colorScheme.primary,
        height: 60.h,
        padding: EdgeInsets.symmetric(horizontal: 20.h),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            Text("Order Info",
                style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStatus(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10.h), // Reduce margin if needed
      padding: EdgeInsets.symmetric(horizontal: 18.h, vertical: 12.h),
      decoration: AppDecoration.fFFFFFDropShadow.copyWith(
        borderRadius: BorderRadiusStyle.roundedBorder5,
        color: AppDecoration.fillPrimary.color, // Set primary color
      ),
      width: MediaQuery.of(context).size.width * 0.9, // 90% of screen width
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(top: 2.h),
              child: Text(
                "Payment Info",
                style: CustomTextStyles.titleMediumWhiteA700SemiBold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionDetails(BuildContext context) {
    // Normalize payment mode for case-insensitive comparison
    final normalizedPaymentMode = ordpaymentmode.toLowerCase().trim();

    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (normalizedPaymentMode == 'mobile_payment') ...[
            _buildOrderRow(
                "Payment Method:", Paymode.isNotEmpty ? Paymode : "M-Pesa"),
            SizedBox(height: 15.h),
            if (transactionId.isNotEmpty)
              _buildOrderRow("Transaction ID:", transactionId),
            SizedBox(height: 15.h),
            if (transactionDate.isNotEmpty)
              _buildOrderRow("Transaction Date:", transactionDate),
            SizedBox(height: 15.h),
            _buildOrderRow("Transaction Status:",
                transactionstatus.isNotEmpty ? transactionstatus : "N/A"),
            SizedBox(height: 15.h),
            _buildOrderRow("Total Amount:", "KSH $totalAmount"),
            SizedBox(height: 15.h),
          ] else if (normalizedPaymentMode == 'insurance') ...[
            _buildOrderRow(
                "Payment Method:", Paymode.isNotEmpty ? Paymode : "Insurance"),
            SizedBox(height: 15.h),
            _buildOrderRow("Policy Number:",
                policyNumber.isNotEmpty ? policyNumber : "N/A"),
            SizedBox(height: 15.h),
            _buildOrderRow(
                "Name:", insuranceName.isNotEmpty ? insuranceName : "N/A"),
            SizedBox(height: 15.h),
            _buildOrderRow("Total Amount:", "KSH $totalAmount"),
            SizedBox(height: 15.h),
          ] else if (normalizedPaymentMode == 'coupon') ...[
            _buildOrderRow(
                "Payment Method:", Paymode.isNotEmpty ? Paymode : "By Coupon"),
            SizedBox(height: 15.h),
            _buildOrderRow(
                "GUID:", coupon_guid.isNotEmpty ? coupon_guid : "N/A"),
            SizedBox(height: 15.h),
            _buildOrderRow("Guardian Name:",
                guardian_name.isNotEmpty ? guardian_name : "N/A"),
            SizedBox(height: 15.h),
            _buildOrderRow("Guardian Phone:",
                guardian_phone.isNotEmpty ? guardian_phone : "N/A"),
            SizedBox(height: 15.h),
            _buildOrderRow("Organization Name:",
                organization_name.isNotEmpty ? organization_name : "N/A"),
            SizedBox(height: 15.h),
            _buildOrderRow("Beneficiary Name:",
                beneficiary_name.isNotEmpty ? beneficiary_name : "N/A"),
            SizedBox(height: 15.h),
            _buildOrderRow("Beneficiary DOB:",
                beneficiary_dob.isNotEmpty ? beneficiary_dob : "N/A"),
            SizedBox(height: 15.h),
            _buildOrderRow("Status:", status.isNotEmpty ? status : "N/A"),
            SizedBox(height: 15.h),
            _buildOrderRow("Total Amount:", "KSH $totalAmount"),
            SizedBox(height: 15.h),
          ] else if (ordpaymentmode.isNotEmpty) ...[
            // Default case for unknown payment modes - still show payment method and total
            _buildOrderRow("Payment Method:",
                Paymode.isNotEmpty ? Paymode : ordpaymentmode),
            SizedBox(height: 15.h),
            _buildOrderRow("Transaction Status:",
                transactionstatus.isNotEmpty ? transactionstatus : "N/A"),
            SizedBox(height: 15.h),
            _buildOrderRow("Total Amount:", "KSH $totalAmount"),
            SizedBox(height: 15.h),
          ],
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildTransactionDetailsold(BuildContext context) {
    return Container(
      width: double.infinity, // Ensures full width
      margin: EdgeInsets.symmetric(horizontal: 10.h), // Adjust margin as needed
      padding: EdgeInsets.symmetric(horizontal: 18.h, vertical: 30.h),
      decoration: AppDecoration.ffffff,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Align text properly
        children: [
          _buildOrderRow("Payment Method  :", "M-Pesa"),
          SizedBox(height: 22.h),
          _buildOrderRow("Transaction Id  :", "45321"),
          SizedBox(height: 22.h),
          _buildOrderRow("Transaction Date :", "05-feb-2025"),
          SizedBox(height: 22.h),
          _buildOrderRow("Total Amounts  :", "\KSH $totalAmount"),
        ],
      ),
    );
  }

// Helper widget to improve structure
  Widget _buildOrderRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        Align(
          alignment: Alignment.topLeft,
          child: Text(
            value,
            style: TextStyle(fontSize: 11),
          ),
        )
      ],
    );
  }

  /// Common widget
  Widget _buildOrderId(
    BuildContext context, {
    required String orderidOne,
    required String zipcode,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          orderidOne,
          style: CustomTextStyles.titleMediumGray800.copyWith(
            color: appTheme.gray800,
          ),
        ),
        Text(
          zipcode,
          style: CustomTextStyles.titleMediumGray800.copyWith(
            color: appTheme.gray800,
          ),
        )
      ],
    );
  }
}
