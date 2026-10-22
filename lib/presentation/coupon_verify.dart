import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../presentation/doctor/order_list_screen/order_list_screen.dart';
import 'order_list_screen/order_list_screen.dart';

import '../../../core/app_export.dart';

class GuardianOtpInputScreen extends StatefulWidget {
  GuardianOtpInputScreen();

  @override
  _GuardianOtpInputScreenState createState() => _GuardianOtpInputScreenState();
}

class _GuardianOtpInputScreenState extends State<GuardianOtpInputScreen> {
  List<TextEditingController> otpControllers =
      List.generate(6, (index) => TextEditingController());
  bool _isResending = false;
  String? phone;
  @override
  void initState() {
    super.initState();
    loadUserData();
    loadGuardianFormData();
  }

  Map<String, dynamic>? guardianFormData;

  Future<void> loadGuardianFormData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? formDataString = prefs.getString("guardianForm");

    if (formDataString != null) {
      setState(() {
        guardianFormData = json.decode(formDataString);
      });
    }
  }

  int? usr_id;
  String userType = "";
  Future<void> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userDataString = prefs.getString('userData');
    if (userDataString != null) {
      Map<String, dynamic> userData = json.decode(userDataString);
      setState(() {
        usr_id = userData['id'];
        userType = userData['usr_user_type'].toString();
      });
    }
    phone = prefs.getString('phone');
  }

  @override
  Widget build(BuildContext context) {
    String lastFourDigits = "1855"; // Placeholder last digits
    String mOtpview =
        "Enter OTP provided by the Guardian. OTP sent to (+xxx) xxx xx";
    String MOtphead = "🛡️ Guardian Verification";

    return Scaffold(
      backgroundColor: appTheme.whiteA700,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildTopHeader(),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 40),
                  CustomImageView(
                    imagePath: ImageConstant.imgRectangle159,
                    height: 178,
                    width: 194,
                  ),
                  SizedBox(height: 30),
                  Text(
                    MOtphead,
                    style: CustomTextStyles.headlineSmallSemiBold,
                  ),
                  SizedBox(height: 20),
                  Text(
                    '$mOtpview $lastFourDigits',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          height: 1.75,
                        ),
                  ),
                  SizedBox(height: 20),
                  _buildOtpFields(),
                  SizedBox(height: 24),
                  _buildResendOtpButton(),
                  SizedBox(height: 24),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      color: theme.colorScheme.primary,
      height: 60,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            "Enter OTP",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 40,
          height: 50,
          child: TextField(
            controller: otpControllers[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              counterText: "",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                FocusScope.of(context).nextFocus();
              } else if (value.isEmpty && index > 0) {
                FocusScope.of(context).previousFocus();
              }
            },
          ),
        );
      }),
    );
  }

  Widget _buildResendOtpButton() {
    return TextButton(
      onPressed: _isResending ? null : _resendOTP,
      child: _isResending
          ? CircularProgressIndicator()
          : Text("Resend OTP", style: TextStyle(color: Colors.blue)),
    );
  }

  Future<void> _resendOTP() async {
    setState(() {
      _isResending = true;
    });

    try {
      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('send_guardian_otp')),
        body: {'phone': phone, 'usr_id': usr_id.toString()},
      );

      setState(() {
        _isResending = false;
      });

      if (response.statusCode == 200) {
        _showMessage("OTP resent successfully!", Colors.green);
      } else {
        _showMessage("Failed to resend OTP.", Colors.red);
      }
    } catch (e) {
      setState(() {
        _isResending = false;
      });
      _showMessage("Error resending OTP: $e", Colors.red);
    }
  }

  Future<bool> _verifyOTP(String otp) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('verify_otp')),
        body: {
          'usr_id': usr_id.toString(),
          'usr_otp': otp,
        },
      );
      //print(response.body);
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      _showError("Error verifying OTP: $e");
      return false;
    }
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: () async {
        String otp = otpControllers.map((c) => c.text).join();
        if (otp.length != 6) {
          _showError("Please enter a valid 6-digit OTP.");
          return;
        }

        bool isOtpValid = await _verifyOTP(otp);
        if (isOtpValid) {
          submitGuardianForm();
        } else {
          _showError("Invalid OTP. Please try again.");
        }
      },
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 50.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      child: Text(
        "Verify",
        style: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Future<void> submitGuardianForm() async {
    if (guardianFormData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No data found to submit.")),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('save_voupen_info')),
        body:
            guardianFormData, // No need to json.encode() for x-www-form-urlencoded
      );
      print(response.body);
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
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _updateGuardianStatus() async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('guardian_orderupdate')),
        body: {
          'usr_id': usr_id.toString(),
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Guardian verification successful!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // or navigate to next screen
        }
      } else {
        _showError("Failed to update order status.");
      }
    } catch (e) {
      _showError("Error updating status: $e");
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
