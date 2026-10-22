import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../core/services/biometric_auth_service.dart';
import '../../core/utils/auth_navigation.dart';
import '../../core/services/active_patient_service.dart';
import '../full_slider_screen/full_slider_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), _handleStartupNavigation);
  }

  Future<void> _handleStartupNavigation() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final sessionToken = prefs.getString('sessionToken');
    final userDataString = prefs.getString('userData');

    if (sessionToken == null ||
        sessionToken.isEmpty ||
        userDataString == null ||
        userDataString.isEmpty) {
      _navigateToFullSlider();
      return;
    }

    final userData = json.decode(userDataString) as Map<String, dynamic>;
    final userType = userData['usr_user_type']?.toString();
    if (userType == null || userType.isEmpty) {
      _navigateToFullSlider();
      return;
    }

    final biometricEnabled = await BiometricAuthService.isBiometricEnabled();
    if (biometricEnabled) {
      final authenticated = await BiometricAuthService.authenticate(
        reason: 'Verify your identity to continue to QuikDawa',
      );
      if (!mounted) return;
      if (authenticated) {
        await ActivePatientService.instance.initialize();
        await AuthNavigation.navigateToDashboardForUserType(context, userType);
      } else {
        await BiometricAuthService.clearSessionPreservingPreferences();
        _navigateToFullSlider();
      }
      return;
    }

    await ActivePatientService.instance.initialize();
    await AuthNavigation.navigateToDashboardForUserType(context, userType);
  }

  void _navigateToFullSlider() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => FullSliderScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0XFF4675C0),
      body: SafeArea(
        child: Container(
          width: double.maxFinite,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.maxFinite,
                  padding: EdgeInsets.symmetric(vertical: 34.h),
                  decoration: AppDecoration.gradientBlueGrayEToPrimary,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Spacer(flex: 40),
                      SizedBox(
                        height: 302.h,
                        width: 336.h,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Text(
                              "QuikDawa",
                              style: CustomTextStyles.displayMediumExtraBold,
                            ),
                            CustomImageView(
                              imagePath: ImageConstant.imgRectangle159,
                              height: 174.h,
                              width: 184.h,
                              alignment: Alignment.topCenter,
                            ),
                          ],
                        ),
                      ),
                      Spacer(flex: 59),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          "Copyright © QuikDawa 2024. All Rights Reserved.",
                          style: CustomTextStyles.bodyLargeGray5001,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
