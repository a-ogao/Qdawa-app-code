import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../core/app_export.dart';
import '../../core/config/app_config.dart';
import 'package:http/http.dart' as http;
import '../../theme/custom_button_style.dart';
import '../../widgets/custom_elevated_button.dart';
import 'forgot_password_new_password_screen.dart';

class ForgotPasswordOtpScreen extends StatefulWidget {
  final String identifier;
  final String? maskedPhone;

  const ForgotPasswordOtpScreen({
    Key? key,
    required this.identifier,
    this.maskedPhone,
  }) : super(key: key);

  @override
  ForgotPasswordOtpScreenState createState() => ForgotPasswordOtpScreenState();
}

class ForgotPasswordOtpScreenState extends State<ForgotPasswordOtpScreen> {
  TextEditingController otpController = TextEditingController();
  String errorMessage = '';
  bool isResending = false;
  bool isVerifying = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Color(0XFF4675C0),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Verify OTP",
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
              Icons.sms,
              size: 48,
              color: Color(0XFF4675C0),
            ),
          ),
          SizedBox(height: 24),
          Text(
            "Enter Verification Code",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            widget.maskedPhone != null
                ? "OTP sent to ${widget.maskedPhone}"
                : "Enter the 6-digit code sent to your registered mobile number",
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
              text: isVerifying ? "Verifying..." : "Verify",
              buttonStyle: CustomButtonStyles.fillPrimary,
              buttonTextStyle: CustomTextStyles.titleMediumWhiteA700Bold18,
              onPressed: isVerifying ? null : () => verifyOTP(context),
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

  Future<void> verifyOTP(BuildContext context) async {
    String otp = otpController.text.trim();

    if (otp.isEmpty || otp.length != 6) {
      setState(() {
        errorMessage = "Please enter a valid 6-digit OTP";
      });
      return;
    }

    setState(() {
      isVerifying = true;
      errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('forgot_password_verify_otp')),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {
          'identifier': widget.identifier,
          'otp_code': otp,
        },
      ).timeout(const Duration(seconds: 30));

      final responseData = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        if (responseData['success'] == true || responseData['status'] == 'success') {
          final verificationToken = responseData['data']?['verification_token'];
          
          if (verificationToken != null && mounted) {
            // Navigate to new password screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ForgotPasswordNewPasswordScreen(
                  identifier: widget.identifier,
                  verificationToken: verificationToken,
                ),
              ),
            );
          } else {
            setState(() {
              errorMessage = "Verification token not received. Please try again.";
              isVerifying = false;
            });
          }
        } else {
          setState(() {
            errorMessage = responseData['message'] ?? "Invalid OTP. Please try again.";
            isVerifying = false;
          });
        }
      } else {
        setState(() {
          errorMessage = responseData['message'] ?? "Verification failed. Please try again.";
          isVerifying = false;
        });
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        errorMessage = "Request timed out. Please try again.";
        isVerifying = false;
      });
    } catch (error) {
      debugPrint('verifyOTP error: $error');
      if (!mounted) return;
      setState(() {
        errorMessage = "Something went wrong. Please try again.";
        isVerifying = false;
      });
    }
  }

  Future<void> resendOTP() async {
    setState(() {
      isResending = true;
      otpController.clear();
      errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('forgot_password_send_otp')),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {
          'identifier': widget.identifier,
        },
      ).timeout(const Duration(seconds: 30));

      final responseData = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        if (responseData['success'] == true || responseData['status'] == 'success') {
          final maskedPhone = responseData['data']?['masked_phone'] ?? widget.maskedPhone;
          setState(() {
            errorMessage = "OTP resent successfully!";
          });
          // Update masked phone if available
          if (maskedPhone != null && maskedPhone != widget.maskedPhone) {
            // You might want to update the header text here
          }
        } else {
          setState(() {
            errorMessage = responseData['message'] ?? "Failed to resend OTP. Please try again.";
          });
        }
      } else {
        setState(() {
          errorMessage = responseData['message'] ?? "Failed to resend OTP. Please try again.";
        });
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        errorMessage = "Request timed out. Please try again.";
      });
    } catch (e) {
      debugPrint('resendOTP error: $e');
      if (!mounted) return;
      setState(() {
        errorMessage = "An error occurred. Please try again.";
      });
    } finally {
      if (mounted) {
        setState(() {
          isResending = false;
        });
      }
    }
  }
}

