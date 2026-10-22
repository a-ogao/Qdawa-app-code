import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/app_export.dart';
import '../../core/config/app_config.dart';
import '../../widgets/custom_icon_button.dart';
import '../quotation_list_screen/quotationrequest_patient_screen.dart';
import '../order_list_screen/order_list_screen.dart';
import '../scan_prescription_screen/scan_prescription_screen.dart';
import '../../core/app_export.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/custom_button_style.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_switch.dart';
import '../../widgets/custom_text_form_field.dart';

class PatientViewScreen extends StatefulWidget {
  final String patientid; // Pass transaction ID dynamically

  const PatientViewScreen({Key? key, required this.patientid})
      : super(key: key);

  @override
  _PatientViewScreenState createState() => _PatientViewScreenState();
}

class _PatientViewScreenState extends State<PatientViewScreen> {
  Map<String, dynamic>? patients;
  Map<String, dynamic>? doctor;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPatientDetails(widget.patientid);
    Future.delayed(Duration(seconds: 3), () {
      // _checkSessionToken();
      //_navigateToFullSlider();
    });
  }

  void _navigateToFullSlider() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => OrderListScreen()),
    );
  }

  Future<void> fetchPatientDetails(String patientid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    print(patientid);
    try {
      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('get_patientid')),

        body: {
          "patientid": patientid.toString()
        }, // Sending the qid as POST data
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        doctor = jsonResponse["doctor"]; // Extract "data" object
        patients = jsonResponse["patients"];
        await prefs.setString('patientid', patients!['id'].toString());
        await prefs.setString('scantype', "userside");
        setState(() {
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
      appBar: AppBar(
        title: Text(
          "Patient Details", // ✅ Title in center
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        centerTitle: true, // ✅ Ensures title is centered
        backgroundColor: theme.colorScheme.primary, // ✅ Customize as needed
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white), // ✅ Back arrow
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Container(
                height: SizeUtils.height,
                width: double.maxFinite,
                padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 22.h),
                child: Column(
                  children: [
                    SizedBox(height: 10), // Add spacing
                    _buildQuotationHeader(context),
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildTransactionDetails(),
                      ),
                    ),

                    CustomElevatedButton(
                      text: "Scan Prescription",
                      margin: EdgeInsets.only(left: 16.h, right: 14.h),
                      rightIcon: Container(
                        margin: EdgeInsets.only(left: 15.h),
                        child: CustomImageView(
                          imagePath: ImageConstant.imgArrowrightGray5003,
                          height: 24.h,
                          width: 24.h,
                          fit: BoxFit.contain,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ScanPrescriptionScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget buildTransactionDetails() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildTopHeader(context),
          SizedBox(height: 24),
          _buildQuotationHeader(context),
          _buildTransactionDetails(),
          SizedBox(height: 30),
          _buildAddBalanceSection(context),
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
              "Patient Details",
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
            "Here is your Patient details",
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
                    text: "\$${patients!['usr_first_name'] ?? '0.00'}",
                    style: CustomTextStyles.titleLargePrimary),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAddBalanceSection(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScanPrescriptionScreen(),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 18.0),
        padding: EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8.0,
              spreadRadius: 1.0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Scan Prescription",
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(
              Icons.qr_code_scanner,
              size: 40.0,
            ),
          ],
        ),
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
          Padding(
            padding: EdgeInsets.only(right: 0.h),
            child: CustomTextFormField(
              hintText: patients!['usr_username'].isNotEmpty
                  ? patients!['usr_username']
                  : 'Malibu Pharmacy Limited',
              textInputAction: TextInputAction.done,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 0.h,
                vertical: 0.h,
              ),
              hintStyle: TextStyle(
                color: Colors.white,
                fontSize: 16.0,
              ),
              borderDecoration: TextFormFieldStyleHelper.fillPrimary,
              fillColor: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildQuotationHeader(BuildContext context) {
    return Container(
      width: double.maxFinite,
      margin: EdgeInsets.only(right: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 12.h),
      decoration: AppDecoration.fillPrimary,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align left & right
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Section: Quotation Request ID
          Text(
            patients!['usr_username'],
            style: CustomTextStyles.titleMediumWhiteA700SemiBold,
          ),

          // Right Section: Prescription View Icon
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
          _buildDetailRow("Name:",
              patients!['usr_first_name'] ?? patients!['usr_username']),
          _buildDetailRow("Email:", patients!['usr_email'] ?? "N/A"),
          _buildDetailRow("Orders:", "2" ?? "N/A"),
          _buildDetailRow("Assigned Doctor:", doctor!['usr_username'] ?? "N/A"),
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
