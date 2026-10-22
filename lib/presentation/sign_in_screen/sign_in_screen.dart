import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../core/config/app_config.dart';
import '../../core/services/notification_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../user_verification_screen/user_verification_screen.dart';
import '../sign_up_screen/sign_up_screen.dart';
import '../forget_password/forget_password.dart';
import '../privacy_policy/privacy_policy.dart';
import '../../widgets/app_version_label.dart';
import '../../core/services/biometric_auth_service.dart';
import '../../core/utils/auth_navigation.dart';
import '../../core/services/active_patient_service.dart';

class SignInScreen extends StatefulWidget {
  SignInScreen({Key? key}) : super(key: key);

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  TextEditingController emailoneController = TextEditingController();
  TextEditingController hiddenATMNoController = TextEditingController();
  bool isLoading = false;
  bool _obscureText = true;
  bool remembermeone = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _hasStoredSession = false;

  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    loadSavedCredentials();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final available = await BiometricAuthService.canCheckBiometrics();
    final enabled = await BiometricAuthService.isBiometricEnabled();
    final hasSession = await BiometricAuthService.hasActiveSession();
    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled;
      _hasStoredSession = hasSession;
    });
  }

  Future<bool> _requireBiometricIfEnabled(String reason) async {
    if (!_biometricEnabled) return true;
    return BiometricAuthService.authenticate(reason: reason);
  }

  Future<void> _navigateAfterLogin(
    BuildContext context,
    Map<String, dynamic> userData,
    String verifyuser,
  ) async {
    if (verifyuser == '1') {
      final authenticated = await _requireBiometricIfEnabled(
        'Verify your identity to sign in to QuikDawa',
      );
      if (!authenticated) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Biometric authentication required to continue.'),
            backgroundColor: Color(0XFF4675C0),
          ),
        );
        return;
      }
    }

    if (!mounted) return;

    await ActivePatientService.instance.initialize();

    if (verifyuser == '1') {
      final userType = userData['usr_user_type']?.toString() ?? '';
      await AuthNavigation.navigateToDashboardForUserType(context, userType);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const UserVerificationScreen(),
        ),
      );
    }
  }

  Future<void> _loginWithBiometric() async {
    if (!_biometricEnabled || !_hasStoredSession) return;

    final authenticated = await BiometricAuthService.authenticate(
      reason: 'Verify your identity to sign in to QuikDawa',
    );
    if (!authenticated || !mounted) return;

    await AuthNavigation.navigateFromStoredSession(context);
  }

  Future<void> loadSavedCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedEmail = prefs.getString('saved_email');
    String? savedPassword = prefs.getString('saved_password');
    bool? savedRemember = prefs.getBool('remember_me');

    if (savedRemember ?? false) {
      setState(() {
        emailoneController.text = savedEmail ?? '';
        hiddenATMNoController.text = savedPassword ?? '';
        remembermeone = true;
      });
    }
  }

  final String apiUrl = AppConfig.buildApiUrl('login');

  Future<void> login(BuildContext context) async {
    if (_formKey.currentState?.validate() ?? false) {
      String email = emailoneController.text;
      String password = hiddenATMNoController.text;

      setLoadingState(true);

      try {
        debugPrint('Login attempt: $email -> $apiUrl');
        var response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {
            'usr_email': email,
            'usr_password_hash': password,
          },
        );

        setLoadingState(false);

        debugPrint('Login response: status=${response.statusCode}, body=${response.body.length} chars');
        if (response.body.length < 500) {
          debugPrint('Login response body: ${response.body}');
        } else {
          debugPrint('Login response body (first 500 chars): ${response.body.substring(0, 500)}');
        }

        if (response.statusCode == 200) {
          var data = jsonDecode(response.body);
          if (data.containsKey('token') && data.containsKey('user')) {
            final userToken = data['token'];
            final userData = data['user'];
            final verifyuser = data['verify_user'];
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('sessionToken', userToken);
            await prefs.setString('userData', json.encode(userData));
            if (remembermeone) {
              await prefs.setString('saved_email', email);
              await prefs.setString('saved_password', password);
              await prefs.setBool('remember_me', true);
            } else {
              await prefs.remove('saved_email');
              await prefs.remove('saved_password');
              await prefs.setBool('remember_me', false);
            }
            
            // Register device for push notifications after successful login
            if (verifyuser == '1') {
              await NotificationService.requestPermissionAndRegister(userToken, context: context);
            }
            
            await _navigateAfterLogin(context, userData, verifyuser.toString());
          }
        } else {
          String errorMessage = 'Login failed (${response.statusCode})';
          try {
            var errorData = jsonDecode(response.body);
            errorMessage = errorData['message']?.toString() ?? errorMessage;
          } catch (_) {
            if (response.body.contains('<!DOCTYPE') || response.body.contains('<html')) {
              errorMessage = 'Server error. Please try again later.';
              debugPrint('Login: Server returned HTML instead of JSON - likely server-side error');
            }
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Color(0XFF4675C0),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } catch (e, stackTrace) {
        setLoadingState(false);
        debugPrint('Login ERROR: $e');
        debugPrint('Login STACK TRACE: $stackTrace');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void setLoadingState(bool state) {
    setState(() {
      isLoading = state;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0XFF4675C0).withOpacity(0.1),
                  Colors.white,
                  Colors.white,
                ],
                stops: [0.0, 0.3, 1.0],
              ),
            ),
          ),

          SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Enhanced header section
                    _buildEnhancedHeader(),

                    // Main form container
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 24.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 24,
                            offset: Offset(0, 8),
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(32.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Welcome text
                            _buildWelcomeSection(),

                            SizedBox(height: 32.h),

                            // Username field
                            _buildEnhancedTextField(
                              controller: emailoneController,
                              hintText: "Username",
                              prefixIcon: Icons.person_outline,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Username cannot be empty';
                                }
                                return null;
                              },
                            ),

                            SizedBox(height: 24.h),

                            // Password field
                            _buildEnhancedTextField(
                              controller: hiddenATMNoController,
                              hintText: "Password",
                              prefixIcon: Icons.lock_outline,
                              isPassword: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password cannot be empty';
                                } else if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),

                            SizedBox(height: 24.h),

                            // Remember me and forgot password
                            _buildRememberAndForgot(),

                            SizedBox(height: 32.h),

                            // Sign in button
                            _buildEnhancedSignInButton(),

                            if (_biometricAvailable &&
                                _biometricEnabled &&
                                _hasStoredSession) ...[
                              SizedBox(height: 20.h),
                              _buildBiometricLoginButton(),
                            ],

                            SizedBox(height: 24.h),

                            // Terms and sign up
                            _buildTermsAndSignUp(),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 32.h),

                    // Copyright
                    _buildCopyright(),

                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ),

          // Enhanced loading overlay
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0XFF4675C0)),
                        strokeWidth: 3,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Signing in...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEnhancedHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.h, vertical: 32.h),
      child: Column(
        children: [
          // Logo with enhanced styling
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0XFF4675C0).withOpacity(0.2),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: CustomImageView(
              imagePath: ImageConstant.imgRectangle159,
              height: 80.h,
              width: 80.h,
            ),
          ),

          SizedBox(height: 24.h),

          // App name with enhanced typography
          Text(
            "QuikDawa",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0XFF4675C0),
              letterSpacing: 1.2,
            ),
          ),

          SizedBox(height: 8.h),

          Text(
            "Your Health, Our Priority",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome Back!",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          "Sign in to continue your health journey",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.grey[600],
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? _obscureText : false,
        validator: validator,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Container(
            margin: EdgeInsets.all(12),
            child: Icon(
              prefixIcon,
              color: Color(0XFF4675C0),
              size: 24,
            ),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey[500],
                    size: 24,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Color(0XFF4675C0), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red[300]!, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red[400]!, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildRememberAndForgot() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Remember me checkbox
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Checkbox(
                value: remembermeone,
                onChanged: (bool? value) {
                  setState(() {
                    remembermeone = value ?? false;
                  });
                },
                activeColor: Color(0XFF4675C0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Remember me',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),

        SizedBox(height: 16),

        // Forgot password on separate line
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ForgetPasswordScreen(),
              ),
            );
          },
          child: Text(
            "Forgot Password?",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0XFF4675C0),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBiometricLoginButton() {
    return OutlinedButton.icon(
      onPressed: _loginWithBiometric,
      icon: Icon(Icons.fingerprint, color: Color(0XFF4675C0), size: 28),
      label: Text(
        'Sign in with Biometrics',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0XFF4675C0),
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: Size(double.infinity, 56),
        side: BorderSide(color: Color(0XFF4675C0), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildEnhancedSignInButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Color(0XFF4675C0),
            Color(0XFF4675C0).withOpacity(0.8),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0XFF4675C0).withOpacity(0.3),
            blurRadius: 16,
            offset: Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => login(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          "Sign In",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTermsAndSignUp() {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: "By continuing, you agree to our ",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              WidgetSpan(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PrivacyPolicyScreen(),
                      ),
                    );
                  },
                  child: Text(
                    "Privacy Policy",
                    style: TextStyle(
                      color: Color(0XFF4675C0),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: "Don't have an account? ",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              WidgetSpan(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SignUpScreen(),
                      ),
                    );
                  },
                  child: Text(
                    "Sign up",
                    style: TextStyle(
                      color: Color(0XFF4675C0),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCopyright() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.h),
      child: Column(
        children: [
          Text(
            "Copyright © QuikDawa 2024. All Rights Reserved.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 8.h),
          AppVersionLabel(
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
