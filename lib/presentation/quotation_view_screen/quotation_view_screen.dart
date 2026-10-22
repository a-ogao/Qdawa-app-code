import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../core/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_switch.dart';
import '../../widgets/custom_text_form_field.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../payment_option/payment_option.dart'; // Import your next screen
import '../../widgets/pii_deidentified_badge.dart';
import '../../core/services/biometric_auth_service.dart';
import '../../core/utils/patient_api_context.dart';

class QuotationViewScreen extends StatefulWidget {
  @override
  _QuotationViewScreenState createState() => _QuotationViewScreenState();
}

// ignore_for_file: must_be_immutable
class _QuotationViewScreenState extends State<QuotationViewScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController searchController = TextEditingController();
  List<dynamic> quotations = [];
  Map<String, dynamic> paymentLifecycle = {};
  bool isLoading = true;
  bool isRequestingHold = false;

  final TextEditingController _couponController = TextEditingController();
  bool isValidatingCoupon = false;
  String? appliedCouponCode;
  double? couponOriginalAmount;
  double? couponDiscountAmount;
  double? couponFinalAmount;
  String? couponMessage;
  bool couponValid = false;

  late String rid; // To hold the Request ID
  TextEditingController toponeController = TextEditingController();
  bool isSelectedSwitch = false;

  @override
  void initState() {
    super.initState();
    // Fetch quotations after getting the request ID
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arguments = ModalRoute.of(context)!.settings.arguments as Map;
      rid = arguments['rid'];
      _fetchQuotations(rid);
    });
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  double _getTotalAmount() {
    if (quotations.isEmpty) return 0;
    return double.tryParse(
            quotations.first['quo_total_amount']?.toString() ?? '') ??
        0;
  }

  String _getQuotationId() {
    return quotations.isNotEmpty
        ? quotations.first['qid']?.toString() ?? ''
        : '';
  }

  double get _payableAmount => couponFinalAmount ?? _getTotalAmount();

  Future<void> _validateCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a coupon code')),
      );
      return;
    }

    final qid = _getQuotationId();
    if (qid.isEmpty) return;

    final apiBody = await PatientApiContext.body();

    setState(() {
      isValidatingCoupon = true;
      couponMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('validate_coupon')),
        body: {
          'quo_id': qid,
          'coupon_code': code,
          'usr_id': apiBody['usr_id'] ?? '',
          if (apiBody.containsKey('actor_usr_id'))
            'actor_usr_id': apiBody['actor_usr_id']!,
        },
      );

      if (response.statusCode != 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Coupon validation failed (HTTP ${response.statusCode}). Please try again.',
            ),
          ),
        );
        return;
      }

      final data = json.decode(response.body);
      setState(() {
        couponValid = data['success'] == true;
        couponMessage = data['message']?.toString();
        if (couponValid) {
          appliedCouponCode = code.toUpperCase();
          couponOriginalAmount =
              double.tryParse(data['original_amount']?.toString() ?? '');
          couponDiscountAmount =
              double.tryParse(data['discount_amount']?.toString() ?? '');
          couponFinalAmount =
              double.tryParse(data['final_amount']?.toString() ?? '');
        } else {
          appliedCouponCode = null;
          couponOriginalAmount = null;
          couponDiscountAmount = null;
          couponFinalAmount = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error validating coupon: $e')),
      );
    } finally {
      if (mounted) setState(() => isValidatingCoupon = false);
    }
  }

  void _removeCoupon() {
    setState(() {
      appliedCouponCode = null;
      couponOriginalAmount = null;
      couponDiscountAmount = null;
      couponFinalAmount = null;
      couponValid = false;
      couponMessage = null;
      _couponController.clear();
    });
  }

  Future<void> _requestHoldExtension() async {
    final qid = _getQuotationId();
    if (qid.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hold for 48 Hours'),
        content: const Text(
          'Send a request to the pharmacy to hold this quotation for 48 more hours? '
          'They must approve before the extension applies.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Request Hold'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => isRequestingHold = true);

    try {
      final apiBody = await PatientApiContext.body();
      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('request_quotation_hold')),
        body: {
          'quo_id': qid,
          'usr_id': apiBody['usr_id'] ?? '',
          if (apiBody.containsKey('actor_usr_id'))
            'actor_usr_id': apiBody['actor_usr_id']!,
        },
      );

      final data = json.decode(response.body);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message']?.toString() ?? 'Request completed'),
          backgroundColor:
              data['success'] == true ? Colors.green : Colors.red,
        ),
      );

      if (data['success'] == true) {
        await _fetchQuotations(rid);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to request hold: $e')),
      );
    } finally {
      if (mounted) setState(() => isRequestingHold = false);
    }
  }

  Widget _buildExpiryLifecycleBanner() {
    if (paymentLifecycle['is_unpaid'] != true) {
      return const SizedBox.shrink();
    }

    final showWarning = paymentLifecycle['show_expiry_warning'] == true;
    final holdStatus = paymentLifecycle['hold_status']?.toString();
    final hoursLeft = paymentLifecycle['hours_until_auto_delete'];

    String message;
    Color bgColor;
    Color borderColor;

    if (holdStatus == 'pending') {
      message =
          'Hold extension requested. Waiting for pharmacy approval.';
      bgColor = Colors.blue.shade50;
      borderColor = Colors.blue.shade200;
    } else if (holdStatus == 'approved') {
      message =
          'Hold approved. Please complete payment within ${hoursLeft ?? '?'} hour(s).';
      bgColor = Colors.green.shade50;
      borderColor = Colors.green.shade200;
    } else if (holdStatus == 'rejected') {
      message =
          'Hold request was rejected. Please pay within ${hoursLeft ?? '?'} hour(s) before this quotation is removed automatically.';
      bgColor = Colors.red.shade50;
      borderColor = Colors.red.shade200;
    } else if (showWarning) {
      message =
          'This quotation will expire in the next ${hoursLeft ?? '24'} hour(s) and will be removed automatically. Please pay or request a hold extension.';
      bgColor = Colors.orange.shade50;
      borderColor = Colors.orange.shade200;
    } else if (hoursLeft != null && (hoursLeft as num) > 0) {
      message =
          'Payment pending. Please pay within ${hoursLeft} hour(s) to keep this quotation active.';
      bgColor = Colors.orange.shade50;
      borderColor = Colors.orange.shade200;
    } else {
      message =
          'Payment is overdue. Please complete payment or this quotation may be removed automatically.';
      bgColor = Colors.red.shade50;
      borderColor = Colors.red.shade200;
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        message,
        style: TextStyle(fontSize: 13, color: Colors.grey[800]),
      ),
    );
  }

  Future<void> _fetchQuotations(String rid) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userDataString = prefs.getString('userData');

      if (userDataString == null) {
        // Handle missing userData (e.g., redirect to login)
        print("User data is not available");
        return;
      }
      final Map<String, dynamic> userData = json.decode(userDataString);

      // Extract the 'id' field
      final int? userId = userData['id'];

      if (userId == null) {
        // Handle missing 'id' in userData
        print("User ID is not available in userData");
        return;
      }

      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('get_quotation_details')),
        body: {
          'usr_id': userId.toString(),
          'request_id': rid.toString()
        }, // Pass requestId here
      );
      //print(response.body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          quotations = data['quotations'] ?? [];
          paymentLifecycle =
              Map<String, dynamic>.from(data['payment_lifecycle'] ?? {});
          isLoading = false;
        });
      } else {
        print("Failed to fetch quotations: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching quotations: $e");
    }
  }

  Future<void> _rejectQuote(
      BuildContext context, String qid, String reason) async {
    final String apiUrl = AppConfig.buildApiUrl('rejectquotation'); // Replace with actual API URL

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          "qid": qid.toString(),
          "reason": reason.toString(),
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Quotation cancelled successfully!")),
        );

        Navigator.pop(context); // Close popup
        Navigator.pop(context); // Go back to quotation list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to cancelled quote! Try again.")),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $error")),
      );
    }
  }

  void _showRejectPopup(BuildContext context, String qid) {
    TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Cancel Quote"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Enter the reason for Cancel this quote:"),
              const SizedBox(height: 10),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Type your reason here...",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                String reason = reasonController.text.trim();
                if (reason.isNotEmpty) {
                  _rejectQuote(context, qid, reason); // Call API function
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please enter a reason")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Change button color if needed
                foregroundColor: Colors.white, // Set text color to white
              ),
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _placeOrder(String qid) async {
    try {
      setState(() {
        isLoading = true;
      });

      // API Call
      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('place_order')),
        headers: {"Content-Type": "application/json"},
        body: '{"quo_id": "$qid"}', // Sending the qid as POST data
      );

      if (response.statusCode == 200) {
        print(qid);
        SharedPreferences prefs = await SharedPreferences.getInstance();

        await prefs.setString(
            'trid', qid.toString()); // Save transaction ID as a string

        // Navigate to the success screen after a successful API call
        Navigator.pushNamed(
          context,
          '/transaction_details_screen',
        ); // Adjust the route name
      } else {
        // Handle API failure
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to place the order. Please try again.')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String pharmacy = quotations.isNotEmpty
        ? quotations.first['pha_first_name']?.toString() ?? ""
        : "";

    String status = quotations.isNotEmpty
        ? quotations.first['qre_quotation_status']?.toString() ?? ""
        : "";

    String delivery = quotations.isNotEmpty
        ? quotations.first['quo_delivery_charge']?.toString() ?? ""
        : "";
    String Requestid = '';

    if (quotations.isNotEmpty) {
      Requestid = quotations.first['qre_request_id'].toString();
    }
    final bool pharmacyDeidentified = quotations.isNotEmpty &&
        PiiDeidentifiedBadge.isDeidentified(quotations.first['pii_deidentified']);
    return Scaffold(
      backgroundColor: appTheme.whiteA700,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          "Quotation Details : #$Requestid",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        backgroundColor: theme.colorScheme.primary,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Go back to the previous screen
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Container(
                height: SizeUtils.height,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: SizeUtils.height,
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.h,
                        vertical: 22.h,
                      ),
                      decoration: AppDecoration.fillGray.copyWith(
                        borderRadius: BorderRadiusStyle.roundedBorder30,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildExpiryLifecycleBanner(),
                          // Spacer(flex: 27),
                          Padding(
                            padding: EdgeInsets.only(right: 6.h),
                            child: CustomTextFormField(
                              controller: toponeController,
                              hintText: pharmacy.isNotEmpty
                                  ? "Pharmacy Name : $pharmacy"
                                  : 'Malibu Pharmacy Limited',
                              textInputAction: TextInputAction.done,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20.h,
                                vertical: 14.h,
                              ),
                              hintStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 16.0,
                              ),
                              borderDecoration:
                                  TextFormFieldStyleHelper.fillPrimary,
                              fillColor: theme.colorScheme.primary,
                            ),
                          ),
                          if (pharmacyDeidentified)
                            Padding(
                              padding: EdgeInsets.only(top: 8.h, left: 4.h),
                              child: const Align(
                                alignment: Alignment.centerLeft,
                                child: PiiDeidentifiedBadge(),
                              ),
                            ),
                          _buildDefaultSection(context),
                          Spacer(flex: 72),

                          // Conditional display of buttons or text based on status
                          if (status == 'received') ...[
                            CustomElevatedButton(
                              text:
                                  "Continue to Payment (KES ${_payableAmount.toStringAsFixed(2)})",
                              margin: EdgeInsets.symmetric(horizontal: 16.h),
                              onPressed: () async {
                                final qid = _getQuotationId();
                                final authenticated =
                                    await BiometricAuthService
                                        .authenticateIfEnabled(
                                  reason:
                                      'Verify your identity to confirm this order',
                                );
                                if (!authenticated || !mounted) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Biometric authentication required to confirm order.',
                                        ),
                                      ),
                                    );
                                  }
                                  return;
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PaymentOptionsScreen(
                                      qid: qid,
                                      payableAmount: _payableAmount,
                                      couponCode: appliedCouponCode,
                                      originalAmount:
                                          couponOriginalAmount ?? _getTotalAmount(),
                                      discountAmount: couponDiscountAmount,
                                    ),
                                  ),
                                );
                              },
                              rightIcon: Container(
                                margin: EdgeInsets.only(left: 5.h),
                                child: CustomImageView(
                                  imagePath:
                                      ImageConstant.imgArrowrightGray5003,
                                  height: 24.h,
                                  width: 24.h,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            SizedBox(height: 10.h),
                            if (paymentLifecycle['can_request_hold'] == true)
                              CustomElevatedButton(
                                text: isRequestingHold
                                    ? "Requesting Hold..."
                                    : "Hold for More 48 Hours",
                                margin: EdgeInsets.symmetric(horizontal: 16.h),
                                onPressed: isRequestingHold
                                    ? null
                                    : _requestHoldExtension,
                              ),
                            if (paymentLifecycle['can_request_hold'] == true)
                              SizedBox(height: 10.h),
                            CustomElevatedButton(
                              text: "Cancel Quote",
                              margin: EdgeInsets.symmetric(horizontal: 16.h),
                              onPressed: () {
                                final qid = quotations.isNotEmpty
                                    ? quotations.first['qid']?.toString() ?? ""
                                    : "";
                                _showRejectPopup(
                                    context, qid); // Show rejection popup
                              },
                              rightIcon: Container(
                                margin: EdgeInsets.only(left: 5.h),
                                child: CustomImageView(
                                  imagePath:
                                      ImageConstant.imgArrowrightGray5003,
                                  height: 24.h,
                                  width: 24.h,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ] else if (status == 'cancelled') ...[
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              child: Text(
                                "Order Cancelled",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ] else
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              child: Text(
                                "Order Placed",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // _buildTopHeader(context),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildDefaultSection(BuildContext context) {
    double totalAmount = 0;

    // Calculate the total amount from the quotations list
    for (var quotation in quotations) {
      totalAmount =
          double.tryParse(quotation['quo_total_amount'].toString()) ?? 0;
    }
    String statuss = quotations.isNotEmpty
        ? quotations.first['qre_quotation_status'] ?? ""
        : ""; // Assuming the status field is called 'qre_quotation_status'
    String delivery = quotations.isNotEmpty
        ? quotations.first['quo_delivery_charge'] ?? ""
        : ""; // Assuming the status field is called 'qre_quotation_status'

    // Use delivery charge amount to determine if it's a delivery order
    // If delivery charge > 0, it's a delivery order
    bool isDeliveryOrder =
        quotations.isNotEmpty && (double.tryParse(delivery) ?? 0) > 0;

    return quotations.isEmpty
        ? const Center(
            child: Text("No quotations found."),
          )
        : Container(
            width: double.maxFinite,
            margin: EdgeInsets.only(right: 6.h),
            padding: EdgeInsets.symmetric(vertical: 8.h),
            decoration: AppDecoration.fFFFFFDropShadow.copyWith(
              borderRadius: BorderRadiusStyle.roundedBorder5,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 6.h),
                // Header Row
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.h),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          "Medicine",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                          flex: 2,
                          child: Text(
                            "Dosage",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          )),
                      Expanded(
                          flex: 1,
                          child: Text(
                            "Qty",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          )),
                      Expanded(
                          flex: 1,
                          child: Text(
                            "Price",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          )),
                      Expanded(
                          flex: 2,
                          child: Text(
                            "Amount",
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          )),
                    ],
                  ),
                ),
                Divider(),
                SizedBox(height: 6.h),
                // List of Quotations
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: quotations.length,
                  itemBuilder: (context, index) {
                    final quotation = quotations[index];
                    return Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.h),
                      child: Row(
                        children: [
                          // Sr. Column

                          // Item Name Column
                          Expanded(
                            flex: 3,
                            child: Text(
                              quotation['qit_item_name'] ?? "Unknown",
                              textAlign: TextAlign.left,
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              quotation['qit_item_dosage'] != null
                                  ? quotation['qit_item_dosage'].toString()
                                  : "0",
                              textAlign: TextAlign.left,
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          // Qty Column
                          Expanded(
                            flex: 1,
                            child: Text(
                              quotation['qit_qty'].toString(),
                              textAlign: TextAlign.left,
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          Expanded(
                            flex: 1, // give a bit more space
                            child: Text(
                              quotation['qit_amount_per_unit'].toString(),
                              textAlign: TextAlign.left,
                              style: theme.textTheme.titleSmall,
                              overflow: TextOverflow
                                  .visible, // make sure it's not clipping
                              maxLines: 1,
                              softWrap: false,
                            ),
                          ),

                          // Amount Column (Aligned left)
                          Expanded(
                            flex: 2,
                            child: Text(
                              "\ ${quotation['qit_amount']}",
                              textAlign: TextAlign.right,
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Divider(),
                SizedBox(height: 8.h),
                if (isDeliveryOrder)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment
                                .topRight, // Ensures "Total" stays on the left
                            child: Text(
                              "Delivery Charges :  KSH",
                              style: TextStyle(fontWeight: FontWeight.bold),
                              //style: theme.textTheme.titleSmall,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment
                                .end, // Align everything to the right
                            children: [
                              Text(
                                double.parse(delivery)
                                    .toStringAsFixed(2), // Amount
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                //Divider(),
                Divider(color: appTheme.gray300),
                SizedBox(height: 8.h),

                // Tax Section (Aligned left)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.h),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment
                              .topRight, // Ensures "Total" stays on the left
                          child: Text(
                            "Tax :  KSH",
                            style: TextStyle(fontWeight: FontWeight.bold),
                            // style: theme.textTheme.titleSmall,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              "00.00",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 8.h),
                // Delivery Service Section (Aligned left)

                Divider(color: appTheme.gray300),
                SizedBox(height: 8.h),
                // Total Section (Aligned left)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.h),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Text(
                            "Total :  KSH",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            "${totalAmount.toStringAsFixed(2)}",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (statuss == 'received') ...[
                  SizedBox(height: 12.h),
                  _buildCouponSection(),
                  if (appliedCouponCode != null &&
                      couponDiscountAmount != null &&
                      couponDiscountAmount! > 0) ...[
                    SizedBox(height: 8.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Text(
                                "Coupon Discount :  KSH",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                "-${couponDiscountAmount!.toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Divider(color: appTheme.gray300),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Text(
                                "Total Payable :  KSH",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                _payableAmount.toStringAsFixed(2),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          );
  }

  Widget _buildCouponSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: appTheme.gray300),
          SizedBox(height: 8.h),
          Text(
            'Apply Coupon',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          SizedBox(height: 8.h),
          if (appliedCouponCode == null) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    decoration: InputDecoration(
                      hintText: 'Enter coupon code',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.h,
                        vertical: 10.h,
                      ),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                SizedBox(width: 8.h),
                ElevatedButton(
                  onPressed: isValidatingCoupon ? null : _validateCoupon,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                  ),
                  child: isValidatingCoupon
                      ? SizedBox(
                          width: 18.h,
                          height: 18.h,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Apply',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            ),
            if (couponMessage != null && !couponValid)
              Padding(
                padding: EdgeInsets.only(top: 6.h),
                child: Text(
                  couponMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10.h),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle,
                      color: Colors.green.shade700, size: 18),
                  SizedBox(width: 6.h),
                  Expanded(
                    child: Text(
                      '${appliedCouponCode!} applied',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _removeCoupon,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildTopHeader(BuildContext context) {
    String Requestid = ''; // Declare the pharmacy variable outside the loop

    // Assign a value to pharmacy based on the quotations
    if (quotations.isNotEmpty) {
      Requestid = quotations.first['qre_request_id'].toString();
    }
    return Align(
      alignment: Alignment.topCenter,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        margin: EdgeInsets.zero,
        color: theme.colorScheme.primary,
        shape: RoundedRectangleBorder(
            // borderRadius: BorderRadiusStyle.customBorderTL30,
            ),
        child: Container(
          height: 60.h,
          padding: EdgeInsets.only(
            left: 18.h,
            right: 18.h,
            bottom: 18.h,
          ),
          decoration: AppDecoration.fillPrimary.copyWith(
            borderRadius: BorderRadiusStyle.customBorderTL30,
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.maxFinite,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(
                                context); // Navigate back to the previous page
                          },
                          child: CustomImageView(
                            imagePath: ImageConstant.imgArrowDown,
                            height: 28.h,
                            width: 22.h,
                          ),
                        ),
                        Spacer(
                          flex: 16,
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Text(
                            "Quotation Details :#$Requestid",
                            style: CustomTextStyles.titleMediumWhiteA700Bold
                                .copyWith(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Spacer(
                          flex: 41,
                        ),
                      ],
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
