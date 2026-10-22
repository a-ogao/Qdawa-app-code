import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../../core/config/app_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'pharmacy_prescription_view_screen.dart';

class ViewQuotationScreen extends StatefulWidget {
  final int id;

  const ViewQuotationScreen({required this.id, Key? key}) : super(key: key);

  @override
  _ViewQuotationScreenState createState() => _ViewQuotationScreenState();
}

class _ViewQuotationScreenState extends State<ViewQuotationScreen> {
  List<dynamic> quotations = [];
  bool isLoading = true;
  Map<String, dynamic> paymentLifecycle = {};
  List<TextEditingController> perunitControllers = [];
  List<TextEditingController> amountControllers = [];
  List<TextEditingController> qtyControllers = [];

  @override
  void initState() {
    super.initState();

    fetchQuotationItems(widget.id);
  }

  Future<void> fetchQuotationItems(int id) async {
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
        Uri.parse(AppConfig.buildApiUrl('view_quotation_details')),
        body: {
          'usr_id': userId.toString(),
          'request_id': id.toString(), // Convert to string
        }, // Pass requestId here
      );
      // print(response.body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          quotations = data['quotations'] ?? [];
          paymentLifecycle =
              Map<String, dynamic>.from(data['payment_lifecycle'] ?? {});
          isLoading = false;
          // Initialize controllers after data is set
        });
      } else {
        print("Failed to fetch quotations: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching quotations: $e");
    }
  }

  Future<void> _softDeleteQuotation() async {
    if (quotations.isEmpty) return;

    final quoId = quotations.first['id']?.toString();
    if (quoId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Soft Delete Quotation'),
        content: Text(
          'This quotation has been unpaid for more than 48 hours. '
          'It will be archived and removed from active lists. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = json.decode(prefs.getString('userData') ?? '{}');

      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('soft_delete_unpaid_quotation')),
        body: {
          'pharmacy_id': userData['id'].toString(),
          'quo_id': quoId,
          'reason': 'Unpaid after 48 hours',
        },
      );

      final data = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message']?.toString() ?? 'Request completed'),
          backgroundColor:
              data['success'] == true ? Colors.green : Colors.red,
        ),
      );

      if (data['success'] == true) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete quotation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPaymentLifecycleBanner() {
    if (paymentLifecycle.isEmpty) return SizedBox.shrink();

    final isUnpaid = paymentLifecycle['is_unpaid'] == true;
    final canSoftDelete = paymentLifecycle['can_soft_delete'] == true;
    final hoursLeft = paymentLifecycle['hours_until_soft_delete'];

    if (!isUnpaid) return SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.h),
      decoration: BoxDecoration(
        color: canSoftDelete ? Colors.red.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: canSoftDelete ? Colors.red.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            canSoftDelete
                ? 'Payment not received within 48 hours. You may soft delete this quotation.'
                : 'Awaiting patient payment. Soft delete available in ${hoursLeft ?? '?'} hour(s).',
            style: TextStyle(fontSize: 13, color: Colors.grey[800]),
          ),
          if (canSoftDelete) ...[
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: _softDeleteQuotation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Soft Delete Unpaid Quotation'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuotationDetails(BuildContext context) {
    // Initialize total amount to 0
    String totalAmount = '0';
    if (quotations.isNotEmpty) {
      totalAmount = quotations.first['quo_total_amount'].toString();
    }
    String delivery = '0';
    if (quotations.isNotEmpty) {
      delivery = quotations.first['quo_delivery_charge'].toString();
    }

    // Use delivery charge amount to determine if it's a delivery order
    // If delivery charge > 0, it's a delivery order
    bool isDeliveryOrder =
        quotations.isNotEmpty && (double.tryParse(delivery) ?? 0) > 0;
    // Calculate total amount for each quotation

    return quotations.isEmpty
        ? const Center(child: Text("No quotations found."))
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
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.h),
                  child: Row(
                    children: [
                      Expanded(
                          flex: 3,
                          child: Text(
                            "Item Name",
                          )),
                      Expanded(
                          flex: 2,
                          child: Text(
                            "Dosage",
                          )),
                      // <-- spacing between columns
                      Expanded(
                          flex: 1,
                          child: Text(
                            "Qty",
                          )),
                      Expanded(
                          flex: 2,
                          child: Text(
                            "Price",
                          )),
                      Expanded(
                          flex: 2,
                          child: Text("Amount", textAlign: TextAlign.right)),
                    ],
                  ),
                ),
                Divider(),
                SizedBox(height: 6.h),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: quotations.length,
                  itemBuilder: (context, index) {
                    final quotation = quotations[index];

                    // Update the total amount for each item

                    return Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.h),
                      child: Row(
                        children: [
                          Expanded(
                              flex: 3,
                              child: Text(
                                quotation['qit_item_name'].toString() ??
                                    "Unknown",
                              )),
                          Expanded(
                            flex: 2,
                            child: Text(
                              quotation['qit_item_dosage'] != null
                                  ? quotation['qit_item_dosage'].toString()
                                  : "0",
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                              flex: 1,
                              child: Text(
                                quotation['qit_qty'].toString() ?? "1",
                                style: const TextStyle(
                                  fontSize:
                                      12, // 👈 Change this value to your desired size
                                  // Optional
                                ),
                              )),
                          Expanded(
                              flex: 2,
                              child: Text(
                                quotation['qit_amount_per_unit'].toString() ??
                                    "0",
                                style: const TextStyle(
                                  fontSize:
                                      12, // 👈 Change this value to your desired size
                                  // Optional
                                ),
                              )),
                          Expanded(
                            flex: 2,
                            child: Text(
                              (quotation['qit_amount']?.toString() ?? "00"),
                              style: theme.textTheme.titleSmall,
                              textAlign: TextAlign.right,
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
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "${double.parse(delivery).toStringAsFixed(2)}",

                            style: theme.textTheme.titleSmall,
                            textAlign:
                                TextAlign.right, // Align text to the right
                          ),
                        ),
                      ],
                    ),
                  ),
                //Divider(),
                /* Divider(color: appTheme.gray300),
                SizedBox(height: 8.h),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment
                              .topRight, // Ensures "Total" stays on the left
                          child: Text(
                            "Tax :  KSH",
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              "00.00",
                              style: theme.textTheme.titleSmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                //Divider(),*/
                Divider(color: appTheme.gray300),
                SizedBox(height: 8.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment
                              .topRight, // Ensures "Total" stays on the left
                          child: Text(
                            "Total :  KSH",
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "${double.parse(totalAmount).toStringAsFixed(2)}",
                          style: theme.textTheme.titleSmall,
                          textAlign:
                              TextAlign.right, // Align amount to the right
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    String qreQuotationStatus = '';
    if (quotations.isNotEmpty) {
      qreQuotationStatus =
          quotations.first?['quo_quotation_status']?.toString() ?? '';
    }

    return Scaffold(
      backgroundColor: appTheme.whiteA700,
      appBar: AppBar(
        title: Text(
          "Quotation",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Container(
                height: SizeUtils.height,
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 22.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Spacer(flex: 10),
                    _buildQuotationHeader(context),
                    _buildPaymentLifecycleBanner(),
                    _buildQuotationDetails(context),
                    Spacer(flex: 72),

                    /// ✅ **Conditional Display Logic**
                    if (qreQuotationStatus.toLowerCase() == 'pending' ||
                        qreQuotationStatus.toLowerCase() == 'order placed')
                      Container(
                        padding: EdgeInsets.all(12.h),
                        child: Text(
                          "Quotation Sent to User",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.h,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: EdgeInsets.all(12.h),
                        child: Text(
                          "$qreQuotationStatus",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                            fontSize: 16.h,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  /// Section Widget
  Widget _buildQuotationHeader(BuildContext context) {
    String Requestid = '';
    String? prescriptionId;
    String? doctorId;

    if (quotations.isNotEmpty) {
      Requestid = quotations.first['qre_request_id'].toString();
      // Get prescription_id and doctor_id if available
      prescriptionId = quotations.first['prescription_id']?.toString();
      doctorId = quotations.first['qre_doctor_id']?.toString();
    }
    print("View Quotation - Prescription ID: $prescriptionId");

    return Container(
      width: double.maxFinite,
      margin: EdgeInsets.only(right: 6.h),
      padding: EdgeInsets.symmetric(
        horizontal: 20.h,
        vertical: 12.h,
      ),
      decoration: AppDecoration.fillPrimary,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Section: Quotation Request ID
          Text(
            "Quotation Request #$Requestid",
            style: CustomTextStyles.titleMediumWhiteA700SemiBold,
          ),

          // Right Section: View Prescription Button (if prescription_id available)
          if (prescriptionId != null && prescriptionId.isNotEmpty)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PharmacyPrescriptionViewScreen(
                      prescriptionId: prescriptionId!,
                      doctorId: doctorId,
                    ),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[600],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Icon(
                  Icons.description,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
