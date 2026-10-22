import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_export.dart';
import '../../core/config/app_config.dart';
import '../../widgets/custom_elevated_button.dart';

class ReportCodeScreen extends StatefulWidget {
  @override
  _ReportCodeScreenState createState() => _ReportCodeScreenState();
}

class _ReportCodeScreenState extends State<ReportCodeScreen> {
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool isCheckingStatus = true;
  bool? hasCode;
  String? userId;
  String? userType;
  String? userEmail;

  static const _eligibleTypes = [
    'patient',
    'pharmacist',
    'healthcare_provider',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('userData');
    if (userDataString == null) {
      setState(() => isCheckingStatus = false);
      return;
    }

    final userData = json.decode(userDataString);
    setState(() {
      userId = userData['id']?.toString();
      userType = userData['usr_user_type']?.toString();
      userEmail = userData['usr_email']?.toString();
    });

    await _checkCodeStatus();
  }

  Future<void> _checkCodeStatus() async {
    if (userId == null) {
      setState(() => isCheckingStatus = false);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('report_code_status')),
        body: {'usr_id': userId!},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            hasCode = data['has_code'] == true;
            userEmail = data['email']?.toString() ?? userEmail;
          });
        }
      }
    } catch (_) {
      // Status check is optional; screen still works without it.
    } finally {
      if (mounted) setState(() => isCheckingStatus = false);
    }
  }

  Future<void> _sendOrResendCode() async {
    await _submit(
      'send_report_code',
      hasCode == true
          ? 'Your report code has been resent to your email.'
          : 'Your 8-digit report code has been sent to your email.',
    );
    if (mounted) await _checkCodeStatus();
  }

  Future<void> _resetCode() async {
    await _submit(
      'reset_report_code',
      'A new report code has been sent to your email.',
    );
    if (mounted) await _checkCodeStatus();
  }

  Future<void> _submit(String endpoint, String successFallback) async {
    if (userId == null) {
      _showMessage('User session expired. Please log in again.', isError: true);
      return;
    }

    if (!_eligibleTypes.contains(userType)) {
      _showMessage(
        'Report decryption codes are not available for your account type.',
        isError: true,
      );
      return;
    }

    final password = passwordController.text.trim();
    if (password.isEmpty) {
      _showMessage('Please enter your password to continue.', isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl(endpoint)),
        body: {
          'usr_id': userId!,
          'usr_password_hash': password,
        },
      );

      final data = json.decode(response.body);
      final message = data['message']?.toString() ?? successFallback;

      _showMessage(message, isError: data['success'] != true);
      if (data['success'] == true) {
        passwordController.clear();
      }
    } catch (e) {
      _showMessage('Something went wrong. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  String get _infoText {
    if (isCheckingStatus) {
      return 'Checking your report code status...';
    }
    if (hasCode == false) {
      return 'You do not have a report decryption code yet. Tap "Send Code to Email" to receive your 8-digit code at ${userEmail ?? 'your registered email'}.';
    }
    return 'Your 8-digit report decryption code was sent to ${userEmail ?? 'your registered email'}. Use "Resend Code to Email" if you need it again.';
  }

  @override
  Widget build(BuildContext context) {
    final sendButtonLabel = hasCode == true
        ? 'Resend Code to Email'
        : 'Send Code to Email';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Report Decryption Code',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: theme.colorScheme.primary,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Color(0XFF4675C0)),
            SizedBox(height: 16),
            Text(
              _infoText,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Use this code to open encrypted PDF reports (prescription history, prescription images, and lab reports).',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            SizedBox(height: 24),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.password),
              ),
            ),
            SizedBox(height: 24),
            isLoading
                ? Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomElevatedButton(
                        text: sendButtonLabel,
                        onPressed: _sendOrResendCode,
                      ),
                      SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: isLoading ? null : _resetCode,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Color(0XFF4675C0)),
                        ),
                        child: Text(
                          'Reset Code (Generate New)',
                          style: TextStyle(color: Color(0XFF4675C0)),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
