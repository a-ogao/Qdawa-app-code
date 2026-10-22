import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'order_list_screen/order_list_screen.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_image_view.dart';
import '../presentation/doctor/order_list_screen/order_list_screen.dart';

class InsurancePaymentScreen extends StatefulWidget {
  final String qid;

  InsurancePaymentScreen({required this.qid});

  @override
  _InsurancePaymentScreenState createState() => _InsurancePaymentScreenState();
}

class _InsurancePaymentScreenState extends State<InsurancePaymentScreen> {
  TextEditingController policyNumberController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController dobController = TextEditingController();
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
        userType = userData['usr_user_type'].toString() ?? '';
      });
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
        dobController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  Future<void> submitData() async {
    if (policyNumberController.text.isEmpty || nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("Please fill Policy Number and Insurance Company Name")),
      );
      return;
    }

    Map<String, dynamic> requestData = {
      'policy_number': policyNumberController.text.trim(),
      'name': nameController.text.trim(),
      'usr_id': usr_id.toString(),
      'qid': widget.qid.toString(),
    };

    // Add DOB only if it's provided
    if (dobController.text.isNotEmpty) {
      requestData['dob'] = dobController.text.trim();
    }

    try {
      var response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('save_insurance_info')),
        body: requestData,
      );
      // print(response.body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text("Information saved successfully And Order Placed!")),
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
          "Insurance Info",
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Policy Number"),
            TextField(
              controller: policyNumberController,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            const Text("Insurance Company Name"),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            const Text("Date of Birth (Optional)"),
            TextField(
              controller: dobController,
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
          margin: EdgeInsets.symmetric(horizontal: 16),
          rightIcon: Container(
            margin: EdgeInsets.only(left: 2),
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
