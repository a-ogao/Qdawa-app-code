import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../presentation/dashboard_screen/dashboard_screen.dart';
import '../../presentation/pharmacy/pharmacy_dashboard_screen/pharmacy_dashboard_screen.dart';
import '../../presentation/delivery/delivered_dashboard/delivery_dashboard_screen.dart';
import '../../presentation/doctor/dashboard_screen/dashboard.dart';

class AuthNavigation {
  AuthNavigation._();

  static Future<void> navigateToDashboardForUserType(
    BuildContext context,
    String userType, {
    bool replace = true,
  }) async {
    final Widget screen;
    switch (userType) {
      case 'pharmacist':
        screen = PharmacyDashboardScreen();
        break;
      case 'rider':
        screen = DeliverydashboardScreen();
        break;
      case 'healthcare_provider':
        screen = DoctordashboardScreen();
        break;
      default:
        screen = DashboardScreen();
    }

    if (!context.mounted) return;

    if (replace) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
    }
  }

  static Future<void> navigateFromStoredSession(
    BuildContext context, {
    bool replace = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('userData');
    if (userDataString == null || !context.mounted) return;

    final userData = json.decode(userDataString) as Map<String, dynamic>;
    final userType = userData['usr_user_type']?.toString() ?? '';
    await navigateToDashboardForUserType(context, userType, replace: replace);
  }
}
