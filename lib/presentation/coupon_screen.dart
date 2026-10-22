import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'order_list_screen/order_list_screen.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_image_view.dart';
import '../presentation/doctor/order_list_screen/order_list_screen.dart';
import '../presentation/coupon_verify.dart';

class CouponPaymentScreen extends StatefulWidget {
  final String qid;

  CouponPaymentScreen({required this.qid});

  @override
  _CouponPaymentScreenState createState() => _CouponPaymentScreenState();
}

class _CouponPaymentScreenState extends State<CouponPaymentScreen> {
  TextEditingController guardianNameController = TextEditingController();
  TextEditingController guardianGovtIdController = TextEditingController();
  TextEditingController guardianPhoneController = TextEditingController();
  TextEditingController organizationNameController = TextEditingController();
  TextEditingController beneficiaryNameController = TextEditingController();
  TextEditingController beneficiaryDobController = TextEditingController();

  DateTime? selectedDate;
  int? usr_id;
  String userType = "";

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userDataString = prefs.getString('userData');
    if (userDataString != null) {
      Map<String, dynamic> userData = json.decode(userDataString);
      setState(() {
        usr_id = userData['id'];
        userType = userData['usr_user_type'].toString();
      });
      String? phone = prefs.getString("phone");
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        beneficiaryDobController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  Future<void> submitData() async {
    if (guardianNameController.text.isEmpty ||
        guardianGovtIdController.text.isEmpty ||
        guardianPhoneController.text.isEmpty ||
        organizationNameController.text.isEmpty ||
        beneficiaryNameController.text.isEmpty ||
        beneficiaryDobController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    // Save form data temporarily
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(
        "guardianForm",
        json.encode({
          'guardian_name': guardianNameController.text.trim(),
          'guardian_govt_id': guardianGovtIdController.text.trim(),
          'guardian_phone': guardianPhoneController.text.trim(),
          'organization_name': organizationNameController.text.trim(),
          'beneficiary_name': beneficiaryNameController.text.trim(),
          'beneficiary_dob': beneficiaryDobController.text.trim(),
          'usr_id': usr_id.toString(),
          'qid': widget.qid.toString(),
        }));
    prefs.setString("phone", guardianPhoneController.text.trim());

    // Send OTP API
    final phone = guardianPhoneController.text.trim();
    var response = await http.post(
      Uri.parse(AppConfig.buildApiUrl('send_guardian_otp')),
      body: {'phone': phone.toString(), 'usr_id': usr_id.toString()},
    );
    //print(response.body);
    if (response.statusCode == 200) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GuardianOtpInputScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send OTP")),
      );
    }
  }

  Future<void> submitDataa() async {
    if (guardianNameController.text.isEmpty ||
        guardianGovtIdController.text.isEmpty ||
        guardianPhoneController.text.isEmpty ||
        organizationNameController.text.isEmpty ||
        beneficiaryNameController.text.isEmpty ||
        beneficiaryDobController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    Map<String, dynamic> requestData = {
      'guardian_name': guardianNameController.text.trim(),
      'guardian_govt_id': guardianGovtIdController.text.trim(),
      'guardian_phone': guardianPhoneController.text.trim(),
      'organization_name': organizationNameController.text.trim(),
      'beneficiary_name': beneficiaryNameController.text.trim(),
      'beneficiary_dob': beneficiaryDobController.text.trim(),
      'usr_id': usr_id.toString(),
      'qid': widget.qid.toString(),
    };

    try {
      var response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('save_voupen_info')), // Replace with your actual endpoint
        body: requestData,
      );

      //print(response.body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Information saved successfully!")),
        );
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to save information")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.whiteA700,
      appBar: AppBar(
        backgroundColor: AppDecoration.fillPrimary.color,
        title: const Text(
          "Coupon Info",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Guardian Name"),
            TextField(
              controller: guardianNameController,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            const Text("Guardian Govt ID"),
            TextField(
              controller: guardianGovtIdController,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            const Text("Guardian Phone"),
            TextField(
              controller: guardianPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            const Text("Organization Name"),
            TextField(
              controller: organizationNameController,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            const Text("Beneficiary Name"),
            TextField(
              controller: beneficiaryNameController,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            const Text("Beneficiary Date of Birth"),
            TextField(
              controller: beneficiaryDobController,
              readOnly: true,
              onTap: () => _selectDate(context),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
        child: CustomElevatedButton(
          text: "Next",
          margin: const EdgeInsets.symmetric(horizontal: 16),
          rightIcon: Container(
            margin: const EdgeInsets.only(left: 2),
            child: CustomImageView(
              imagePath: ImageConstant.imgArrowrightGray5003,
              height: 24,
              width: 24,
              fit: BoxFit.contain,
            ),
          ),
          onPressed: submitData,
        ),
      ),
    );
  }
}
