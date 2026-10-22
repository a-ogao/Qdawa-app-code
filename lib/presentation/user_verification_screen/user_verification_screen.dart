import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../core/app_export.dart';
import '../../core/config/app_config.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/custom_elevated_button.dart';
import '../dashboard_screen/dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pharmacy/quotation_requests_pharmacy_screen/quotation_requests_pharmacy_screen.dart';
import '../pharmacy/pharmacy_dashboard_screen/pharmacy_dashboard_screen.dart';
import 'dart:convert';
import '../delivery/delivery_requests/delivery_requests.dart';
import '../delivery/delivered_dashboard/delivery_dashboard_screen.dart';
import 'package:http/http.dart' as http; // Import HTTP package for API call
import '../doctor/dashboard_screen/dashboard.dart';

class UserVerificationScreen extends StatefulWidget {
  const UserVerificationScreen({Key? key}) : super(key: key);

  @override
  _UserVerificationScreenState createState() => _UserVerificationScreenState();
}

class _UserVerificationScreenState extends State<UserVerificationScreen> {
  TextEditingController otpController = TextEditingController();
  String errorMessage = '';
  bool isResending = false;
  String lastFourDigits = '****'; // State to show resend loading
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userDataString = prefs.getString('userData');

    if (userDataString != null) {
      final Map<String, dynamic> userData = json.decode(userDataString);
      String contact = userData['usr_mobile_number'] ?? '0000';

      // Extract last 4 digits
      String contactStr = contact.toString();
      String extractedDigits = contactStr.length >= 4
          ? contactStr.substring(contactStr.length - 4)
          : contactStr;

      setState(() {
        lastFourDigits = extractedDigits;
      });
    }
  }

  // Function to verify OTP
  void verifyOTP(BuildContext context) async {
    String otp = otpController.text.trim();

    if (otp.isEmpty || otp.length != 6) {
      // Ensure OTP is exactly 6 digits
      setState(() {
        errorMessage = "Please enter a valid 6-digit OTP";
      });
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userDataString = prefs.getString('userData');

    if (userDataString != null) {
      final Map<String, dynamic> userData = json.decode(userDataString);
      String userId = userData['id'].toString() ?? '';
      String userType = userData['usr_user_type'].toString() ?? '';

      if (userId.isEmpty) {
        setState(() {
          errorMessage = "User ID not found. Please log in again.";
        });
        return;
      }

      // API URL
      String apiUrl = AppConfig.buildApiUrl('verify_otp');

      try {
        // Make POST request
        final response = await http.post(
          Uri.parse(apiUrl),
          body: {"usr_id": userId.toString(), "usr_otp": otp.toString()},
        );

        final responseData = jsonDecode(response.body);

        if (response.statusCode == 200 && responseData['status'] == "success") {
          final reportCodeMessage =
              responseData['data']?['report_code_message']?.toString();
          if (reportCodeMessage != null && reportCodeMessage.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(reportCodeMessage),
                duration: Duration(seconds: 5),
              ),
            );
          } else if (['patient', 'pharmacist', 'healthcare_provider']
              .contains(userType)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Your 8-digit report decryption code has been sent to your email.'),
                duration: Duration(seconds: 5),
              ),
            );
          }

          // OTP is valid, navigate based on user type
          if (userType == 'pharmacist') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => PharmacyDashboardScreen()),
            );
          } else if (userType == 'rider') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => DeliverydashboardScreen()),
            );
          } else if (userType == 'healthcare_provider') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DoctordashboardScreen()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardScreen()),
            );
          }
        } else {
          // OTP verification failed, show error message
          setState(() {
            errorMessage =
                responseData['message'] ?? "Invalid OTP. Please try again.";
          });
        }
      } catch (error) {
        setState(() {
          errorMessage = "Something went wrong. Please try again.";
        });
      }
    } else {
      setState(() {
        errorMessage = "User data not found. Please log in again.";
      });
    }
  }

  // Function to verify OTP
  /* void verifyOTP(BuildContext context) async {
    String otp = otpController.text.trim();

    if (otp.isEmpty || otp.length != 6) {
      // Ensure OTP is exactly 6 digits
      setState(() {
        errorMessage = "Please enter a valid 6-digit OTP";
      });
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userDataString = prefs.getString('userData');

    if (userDataString != null) {
      final Map<String, dynamic> userData = json.decode(userDataString);
      String userType = userData['usr_user_type'] ?? '';

      if (userType == 'pharmacist') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PharmacyDashboardScreen(),
          ),
        );
      } else if (userType == 'rider') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeliverydashboardScreen(),
          ),
        );
      } else if (userType == 'healthcare_provider') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DoctordashboardScreen()),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(),
          ),
        );
      }
    }
  }*/

  // Function to resend OTP
  Future<void> resendOTP() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userDataString = prefs.getString('userData');
    // print(userDataString);
    String userId = "0";
    if (userDataString != null) {
      final Map<String, dynamic> userData = json.decode(userDataString);
      //  print(userData);
      int userId = userData['id'] ?? '';
      //print(userId);

      String contact =
          userData['usr_mobile_number'] ?? '222'; // Ensure it's an integer

// Convert to String and get the last 4 digits
      String contactStr = contact.toString();
      String lastFourDigits = contactStr.length >= 4
          ? contactStr.substring(contactStr.length - 4)
          : contactStr; // Handle cases where number has less than 4 digits

      setState(() {
        isResending = true;
        otpController.clear();
      });

      try {
        final response = await http.post(
          Uri.parse(AppConfig.buildApiUrl('resend_otp')), // Replace with actual API URL
          body: {
            'usr_id': userId.toString() // Pass the phone number dynamically
          },
        );

        if (response.statusCode == 200) {
          setState(() {
            errorMessage = "OTP resent successfully!";
          });
        } else {
          setState(() {
            errorMessage = "Failed to resend OTP. Try again.";
          });
        }
      } catch (e) {
        setState(() {
          errorMessage = "An error occurred. Please try again.";
        });
      } finally {
        setState(() {
          isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Color(0XFF4675C0),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Verification",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0XFF4675C0).withValues(alpha: 0.05),
              Colors.grey[50]!,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 40),
                _buildHeader(),
                SizedBox(height: 32),
                _buildVerificationCard(),
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0XFF4675C0).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified_user,
              size: 48,
              color: Color(0XFF4675C0),
            ),
          ),
          SizedBox(height: 24),
          Text(
            "Verify Your Account",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "An authentication code has been sent to\n(+xxx) xxx xx$lastFourDigits",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.maxFinite,
            margin: EdgeInsets.symmetric(horizontal: 12.h),
            child: PinCodeTextField(
              appContext: context,
              controller: otpController,
              length: 6,
              keyboardType: TextInputType.number,
              textStyle: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              enableActiveFill: true,
              pinTheme: PinTheme(
                fieldHeight: 56,
                fieldWidth: 50,
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(12),
                inactiveFillColor: Colors.white,
                inactiveColor: Colors.grey.shade300,
                activeFillColor: Colors.white,
                activeColor: Color(0XFF4675C0),
                selectedFillColor: Colors.white,
                selectedColor: Color(0XFF4675C0),
                borderWidth: 1.5,
              ),
              onChanged: (value) {
                setState(() {
                  errorMessage = '';
                });
              },
            ),
          ),
          SizedBox(height: 16),
          if (errorMessage.isNotEmpty)
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                errorMessage,
                style: TextStyle(color: Colors.red, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: CustomElevatedButton(
              text: "Verify",
              buttonStyle: CustomButtonStyles.fillPrimary,
              buttonTextStyle: CustomTextStyles.titleMediumWhiteA700Bold18,
              onPressed: () => verifyOTP(context),
              alignment: Alignment.center,
            ),
          ),
          SizedBox(height: 16),
          GestureDetector(
            onTap: isResending ? null : resendOTP,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "I didn't receive code. ",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  TextSpan(
                    text: "Resend Code",
                    style: TextStyle(
                      color: Color(0XFF4675C0),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: isResending ? " (Resending...)" : "",
                    style: TextStyle(
                      color: Color(0XFF4675C0),
                      fontSize: 16,
                    ),
                  )
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
