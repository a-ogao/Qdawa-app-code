import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../warning_order_ready_dialog/warning_order_ready_dialog.dart';

class AppNavigationScreen extends StatelessWidget {
  const AppNavigationScreen({Key? key})
      : super(
          key: key,
        );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0XFFFFFFFF),
      body: SafeArea(
        child: SizedBox(
          width: 375.h,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Color(0XFFFFFFFF),
                ),
                child: Column(
                  children: [
                    SizedBox(height: 10.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.h),
                      child: Text(
                        "App Navigation",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0XFF000000),
                          fontSize: 20.fSize,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Padding(
                      padding: EdgeInsets.only(left: 20.h),
                      child: Text(
                        "Check your app's UI from the below demo screens of your app.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0XFF888888),
                          fontSize: 16.fSize,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Divider(
                      height: 1.h,
                      thickness: 1.h,
                      color: Color(0XFF000000),
                    )
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0XFFFFFFFF),
                    ),
                    child: Column(
                      children: [
                        _buildScreenTitle(
                          context,
                          screenTitle: "Sign up",
                          onTapScreenTitle: () =>
                              onTapScreenTitle(context, AppRoutes.signUpScreen),
                        ),
                        _buildScreenTitle(
                          context,
                          screenTitle: "Order Track/Status",
                          onTapScreenTitle: () => onTapScreenTitle(
                              context, AppRoutes.orderTrackStatusScreen),
                        ),
                        _buildScreenTitle(
                          context,
                          screenTitle: "Splash",
                          onTapScreenTitle: () =>
                              onTapScreenTitle(context, AppRoutes.splashScreen),
                        ),
                        _buildScreenTitle(
                          context,
                          screenTitle: "Full Slider",
                          onTapScreenTitle: () => onTapScreenTitle(
                              context, AppRoutes.fullSliderScreen),
                        ),
                        _buildScreenTitle(
                          context,
                          screenTitle: "User Verification",
                          onTapScreenTitle: () => onTapScreenTitle(
                              context, AppRoutes.userVerificationScreen),
                        ),
                        _buildScreenTitle(
                          context,
                          screenTitle: "Subscribe",
                          onTapScreenTitle: () => onTapScreenTitle(
                              context, AppRoutes.subscribeScreen),
                        ),
                        _buildScreenTitle(
                          context,
                          screenTitle: "Sign In",
                          onTapScreenTitle: () =>
                              onTapScreenTitle(context, AppRoutes.signInScreen),
                        ),
                        _buildScreenTitle(
                          context,
                          screenTitle: "User Setting",
                          onTapScreenTitle: () => onTapScreenTitle(
                              context, AppRoutes.userSettingScreen),
                        ),
                        _buildScreenTitle(
                          context,
                          screenTitle: "Menu Slide Display",
                          onTapScreenTitle: () => onTapScreenTitle(
                              context, AppRoutes.menuSlideDisplayScreen),
                        ),
                        _buildScreenTitle(
                          context,
                          screenTitle: "Dashboard",
                          onTapScreenTitle: () => onTapScreenTitle(
                              context, AppRoutes.dashboardScreen),
                        ),
                        _buildScreenTitle(
                          context,
                          screenTitle: "Scan Prescription",
                          onTapScreenTitle: () => onTapScreenTitle(
                              context, AppRoutes.scanPrescriptionScreen),
                        ),
                        _buildScreenTitle(
                          context,
                          screenTitle: "Scanned Prescription",
                          onTapScreenTitle: () => onTapScreenTitle(
                              context, AppRoutes.scannedPrescriptionScreen),
                        ),
                        _buildScreenTitle(
                          context,
                          screenTitle: "Pharmacy list",
                          onTapScreenTitle: () => onTapScreenTitle(
                              context, AppRoutes.pharmacyListScreen),
                        ),
                        _buildScreenTitle(
                          context,
                          screenTitle: "Success-Two",
                          onTapScreenTitle: () => onTapScreenTitle(
                              context, AppRoutes.successTwoScreen),
                        ),
                        _buildScreenTitle(
                          context,
                          screenTitle: "Quotation List",
                          onTapScreenTitle: () => onTapScreenTitle(
                              context, AppRoutes.quotationListScreen),
                        ),
                        _buildScreenTitle(
                          context,
                          screenTitle: "Quotation request List",
                          onTapScreenTitle: () => onTapScreenTitle(
                              context, AppRoutes.quotationRequestScreen),
                        ),
                        _buildScreenTitle(
                          context,
                          screenTitle: "Quotation View",
                          onTapScreenTitle: () => onTapScreenTitle(
                              context, AppRoutes.quotationViewScreen),
                        ),
                        _buildScreenTitle(
                          context,
                          screenTitle: "Transaction Details",
                          onTapScreenTitle: () => onTapScreenTitle(
                              context, AppRoutes.transactionDetailsScreen),
                        ),
                        _buildScreenTitle(
                          context,
                          screenTitle: "Order list",
                          onTapScreenTitle: () => onTapScreenTitle(
                              context, AppRoutes.orderListScreen),
                        ),
                        _buildScreenTitle(
                          context,
                          screenTitle: "Quotation Requests -Pharmacy",
                          onTapScreenTitle: () => onTapScreenTitle(context,
                              AppRoutes.quotationRequestsPharmacyScreen),
                        ),
                        _buildScreenTitle(
                          context,
                          screenTitle: "Submit Quotation",
                          onTapScreenTitle: () => onTapScreenTitle(
                              context, AppRoutes.submitQuotationScreen),
                        ),
                        _buildScreenTitle(
                          context,
                          screenTitle: "Order list - Pharmacy",
                          onTapScreenTitle: () => onTapScreenTitle(
                              context, AppRoutes.orderListPharmacyScreen),
                        ),
                        _buildScreenTitle(
                          context,
                          screenTitle: "View Order",
                          onTapScreenTitle: () => onTapScreenTitle(
                              context, AppRoutes.viewOrderScreen),
                        ),
                        _buildScreenTitle(
                          context,
                          screenTitle: "Warning - Order ready  - Dialog",
                          onTapScreenTitle: () => onTapDialogTitle(
                              context, WarningOrderReadyDialog()),
                        ),
                        _buildScreenTitle(
                          context,
                          screenTitle: "View Order - Two",
                          onTapScreenTitle: () => onTapScreenTitle(
                              context, AppRoutes.viewOrderTwoScreen),
                        ),
                        _buildScreenTitle(
                          context,
                          screenTitle: "View Order - Three",
                          onTapScreenTitle: () => onTapScreenTitle(
                              context, AppRoutes.viewOrderThreeScreen),
                        ),
                        _buildScreenTitle(
                          context,
                          screenTitle: "Pharmacy NavBar",
                          onTapScreenTitle: () => onTapScreenTitle(
                              context, AppRoutes.viewPharmacyorderlist),
                        )
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  /// Common click event for dialog
  void onTapDialogTitle(
    BuildContext context,
    Widget className,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: className,
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
        );
      },
    );
  }

  /// Common widget
  Widget _buildScreenTitle(
    BuildContext context, {
    required String screenTitle,
    Function? onTapScreenTitle,
  }) {
    return GestureDetector(
      onTap: () {
        onTapScreenTitle?.call();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Color(0XFFFFFFFF),
        ),
        child: Column(
          children: [
            SizedBox(height: 10.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.h),
              child: Text(
                screenTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0XFF000000),
                  fontSize: 20.fSize,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            SizedBox(height: 10.h),
            SizedBox(height: 5.h),
            Divider(
              height: 1.h,
              thickness: 1.h,
              color: Color(0XFF888888),
            )
          ],
        ),
      ),
    );
  }

  /// Common click event
  void onTapScreenTitle(
    BuildContext context,
    String routeName,
  ) {
    Navigator.pushNamed(context, routeName);
  }
}
