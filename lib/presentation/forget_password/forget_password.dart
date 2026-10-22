import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../core/config/app_config.dart';
import 'package:http/http.dart' as http;
import '../../theme/custom_button_style.dart';
import '../../widgets/custom_elevated_button.dart';
import 'forgot_password_otp_screen.dart';

class ForgetPasswordScreen extends StatefulWidget {
  @override
  _ForgetPasswordScreenState createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final TextEditingController _usernameController = TextEditingController();
  bool _isLoading = false;

  final Color primaryColor = Color(0xFF0057B7); // Set your primary color here

  Future<void> resetPassword() async {
    String identifier = _usernameController.text.trim();

    if (identifier.isEmpty) {
      showSnackbar("Email, username, or phone number is required.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('forgot_password_send_otp')),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {
          'identifier': identifier,
        },
      ).timeout(const Duration(seconds: 30));

      debugPrint('resetPassword status: ${response.statusCode}');
      debugPrint('resetPassword body: ${response.body}');

      Map<String, dynamic>? result;
      try {
        result = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        debugPrint('resetPassword: failed to decode response body as JSON');
      }

      if (!mounted) return;

      if (response.statusCode == 200) {
        if (result?['success'] == true || result?['status'] == 'success') {
          final message = result?['message'] ?? 'OTP sent successfully to your registered mobile number';
          final maskedPhone = result?['data']?['masked_phone'] ?? '';
          
          // Show success message briefly
          showSnackbar(message);
          
          // Navigate to OTP verification screen after a short delay
          Future.delayed(Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ForgotPasswordOtpScreen(
                    identifier: identifier,
                    maskedPhone: maskedPhone,
                  ),
                ),
              );
            }
          });
        } else {
          final errorMessage = result?['message'] ?? 'Failed to send OTP. Please try again.';
          showSnackbar(errorMessage);
        }
      } else {
        final errorMessage = result?['message'] ?? result?['error'] ?? 'Failed to send OTP. Please try again.';
        showSnackbar(errorMessage);
      }
    } on TimeoutException {
      if (!mounted) return;
      showSnackbar('Request timed out. Please check your internet connection and try again.');
    } catch (e) {
      debugPrint('resetPassword error: $e');
      if (!mounted) return;
      showSnackbar('Failed to send OTP. Please check your connection and try again.');
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color(0XFF4675C0),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
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
              Icons.lock_reset,
              size: 48,
              color: Color(0XFF4675C0),
            ),
          ),
          SizedBox(height: 24),
          Text(
            "Reset Password",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Enter your registered email, username, or phone number",
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

  Widget _buildFormCard() {
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
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: "Email, Username, or Phone",
              hintText: "Enter email, username, or phone number",
              labelStyle: TextStyle(color: Colors.grey[600]),
              prefixIcon: Icon(Icons.person, color: Color(0XFF4675C0)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: Color(0XFF4675C0)),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            keyboardType: TextInputType.text,
          ),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: CustomElevatedButton(
              text: _isLoading ? "" : "Reset Password",
              buttonStyle: CustomButtonStyles.fillPrimary,
              buttonTextStyle: CustomTextStyles.titleMediumWhiteA700Bold18,
              onPressed: _isLoading ? null : resetPassword,
              alignment: Alignment.center,
            ),
          ),
          if (_isLoading)
            Container(
              margin: EdgeInsets.only(top: 16),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0XFF4675C0)),
                strokeWidth: 2,
              ),
            ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: CustomElevatedButton(
              text: "Back to Login",
              buttonStyle: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                side: BorderSide(color: Color(0XFF4675C0), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              buttonTextStyle: TextStyle(
                color: Color(0XFF4675C0),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              onPressed: () => Navigator.pop(context),
              alignment: Alignment.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Color(0XFF4675C0),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Forgot Password",
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
                _buildFormCard(),
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
