import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/app_export.dart';
import '../../core/config/app_config.dart';
import '../../widgets/custom_icon_button.dart';
import '../quotation_list_screen/quotationrequest_patient_screen.dart';
import '../order_list_screen/order_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../doctor/order_list_screen/order_list_screen.dart';

class TransactionDetailsScreen extends StatefulWidget {
  final String trid; // Pass transaction ID dynamically

  const TransactionDetailsScreen({Key? key, required this.trid})
      : super(key: key);

  @override
  _TransactionDetailsScreenState createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  Map<String, dynamic>? transactionData;

  bool isLoading = true;
  String userType = "";
  @override
  void initState() {
    super.initState();
    fetchTransactionDetails(widget.trid);
    Future.delayed(Duration(seconds: 3), () {
      // _checkSessionToken();
      _navigateToFullSlider();
    });
  }

  void _navigateToFullSlider() {
    if (userType == 'healthcare_provider') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DoctorOrderListScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OrderListScreen()),
      );
    }
  }

  Future<void> fetchTransactionDetails(String trid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? userDataString = prefs.getString('userData');
    if (userDataString != null) {
      final Map<String, dynamic> userData = json.decode(userDataString);
      String userId = userData['id'].toString() ?? '';
      userType = userData['usr_user_type'].toString() ?? '';

      if (userId.isEmpty) {
        setState(() {
          print("User ID not found. Please log in again.");
        });
        return;
      }
    }
    print(trid);
    try {
      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('get_tra')),

        body: {"quo_id": trid.toString()}, // Sending the qid as POST data
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        setState(() {
          transactionData = jsonResponse["data"]; // Extract "data" object

          print(transactionData);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load transaction');
      }
    } catch (e) {
      print("Error fetching data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.whiteA700,
      body: SafeArea(
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : transactionData == null
                ? Center(child: Text("No Data Found"))
                : buildTransactionDetails(),
      ),
    );
  }

  Widget buildTransactionDetails() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildTopHeader(context),
          SizedBox(height: 22),
          Text(
            "Transaction Detail #${transactionData!['tra_transaction_id'] ?? 'N/A'}",
            style: CustomTextStyles.headlineSmallSemiBold_1,
          ),
          SizedBox(height: 24),
          _buildTransactionSummary(),
          SizedBox(height: 30),
          _buildPaymentStatus(),
          _buildTransactionDetails(),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildTopHeader(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: Container(
        height: 50.h,
        width: double.maxFinite,
        padding: EdgeInsets.symmetric(horizontal: 18.h),
        color: theme.colorScheme.primary,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context), // Navigates back
              child: Icon(
                Icons.arrow_back, // Back arrow icon
                color: Colors.white, // White color for the arrow
                size: 24.h,
              ),
            ),
            Spacer(),
            Text(
              "Transactions Details",
              style: CustomTextStyles.titleMediumWhiteA700Bold,
            ),
            Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionSummary() {
    return Container(
      padding: EdgeInsets.all(22),
      decoration: AppDecoration.fFFFFFDropShadow.copyWith(
        borderRadius: BorderRadiusStyle.roundedBorder8,
      ),
      child: Column(
        children: [
          Text(
            "Here is your transaction details history",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge!.copyWith(height: 1.50),
          ),
          SizedBox(height: 32),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                    text: "Payment Sent\n",
                    style: CustomTextStyles.titleLargeOnPrimary),
                TextSpan(
                    text: "\$${transactionData!['tra_total_amount'] ?? '0.00'}",
                    style: CustomTextStyles.titleLargePrimary),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStatus() {
    return Container(
      padding: EdgeInsets.all(12),
      color: theme.colorScheme.primary,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Payment Status",
              style: CustomTextStyles.titleMediumWhiteA700SemiBold),
          Icon(Icons.check_circle, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildTransactionDetails() {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: AppDecoration.ffffff,
      child: Column(
        children: [
          _buildDetailRow("To:", transactionData!['pha_first_name'] ?? "N/A"),
          _buildDetailRow("Payment Method:",
              transactionData!['tra_transaction_status'] ?? "N/A"),
          _buildDetailRow(
              "Order ID:", transactionData!['ord_id'].toString() ?? "N/A"),
          _buildDetailRow(
              "Purchase Date:", transactionData!['tra_created_dt'] ?? "N/A"),
          _buildDetailRow("Total Amount:",
              "\$${transactionData!['tra_total_amount'] ?? '0.00'}"),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: CustomTextStyles.titleMediumGray800),
          Text(value, style: CustomTextStyles.titleMediumGray800),
        ],
      ),
    );
  }
}
