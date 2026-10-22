import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../quotation_list_screen/quotationrequest_patient_screen.dart'; // Import the SignUpScreen
import '../../core/app_export.dart';
import '../doctor/quotation_list_screen/quotationrequest_patient_screen.dart';

class SuccessTwoScreen extends StatefulWidget {
  const SuccessTwoScreen({Key? key}) : super(key: key);

  @override
  _SuccessTwoScreenState createState() => _SuccessTwoScreenState();
}

class _SuccessTwoScreenState extends State<SuccessTwoScreen> {
  late Future<String?> _requestIdFuture;

  @override
  void initState() {
    super.initState();
    _requestIdFuture = _getRequestId();
    Future.delayed(Duration(seconds: 6), () {
      // _checkSessionToken();
      _navigateToFullSlider();
    });
  }

  String usertype = "";
  // Method to fetch request_id from SharedPreferences
  Future<String?> _getRequestId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userDataString = prefs.getString('userData');

    if (userDataString != null) {
      Map<String, dynamic> userData = json.decode(userDataString);
      usertype = userData['usr_user_type'].toString() ?? '';
    }
    return prefs.getString('request_id');
  }

  void _navigateToFullSlider() {
    if (usertype == 'healthcare_provider') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DQuotationRequestScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => QuotationRequestScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.whiteA700,
      body: SafeArea(
        child: Container(
          width: double.maxFinite,
          // padding: EdgeInsets.only(
          //   left: 20.h,
          //   top: 20.h,
          //   right: 20.h,
          // ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: Container(
                  width: double.maxFinite,
                  decoration: AppDecoration.fillGray.copyWith(
                      // borderRadius: BorderRadiusStyle.roundedBorder30,
                      ),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      _buildTopHeader(context),
                      SizedBox(height: 32.h),
                      Container(
                        height: 524.h,
                        width: double.maxFinite,
                        margin: EdgeInsets.symmetric(horizontal: 18.h),
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            _buildSheetTitle(context),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  /// Section Widget
  Widget _buildTopHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 18.h,
        vertical: 20.h,
      ),
      decoration: AppDecoration.fillPrimary.copyWith(
          // borderRadius: BorderRadiusStyle.customBorderTL30,
          ),
      width: double.maxFinite,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CustomImageView(
            imagePath: ImageConstant.imgArrowDown,
            height: 15.h,
            width: 22.h,
          ),
          Spacer(flex: 28),
          Text(
            "Action Sheet",
            style: CustomTextStyles.titleMediumWhiteA700Bold.copyWith(
              fontSize: 18.0, // Set your desired font size here
            ),
          ),
          Spacer(flex: 41),
        ],
      ),
    );
  }

  /// Section Widget

  /// Section Widget
  Widget _buildSheetTitle(BuildContext context) {
    return FutureBuilder<String?>(
      future: _requestIdFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final requestId = snapshot.data ?? 'N/A';
        return Container(
          width: double.maxFinite,
          margin: EdgeInsets.only(bottom: 84.h),
          padding: EdgeInsets.symmetric(
            horizontal: 30.h,
            vertical: 14.h,
          ),
          decoration: AppDecoration.ffffff.copyWith(
            borderRadius: BorderRadiusStyle.roundedBorder5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 22.h),
              CustomImageView(
                imagePath: ImageConstant.imgQdCorrect2,
                height: 80.h,
                width: 80.h,
              ),
              SizedBox(height: 22.h),
              Text(
                "Success",
                style: theme.textTheme.titleMedium,
              ),
              SizedBox(height: 8.h),
              SizedBox(
                width: double.maxFinite,
                child: Divider(
                  color: appTheme.blueGray800B2,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "Quotation Request Sent to selected pharmacies\nRequest ID: $requestId",
                style: CustomTextStyles.bodyLargeGray700,
              ),
              SizedBox(height: 14.h),
              Text(
                "Done",
                style: CustomTextStyles.titleMediumWhiteA700Bold_1,
              ),
            ],
          ),
        );
      },
    );
  }

  /// Common widget
  Widget _buildInsetRow(
    BuildContext context, {
    required String insetOne,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.center,
          child: Text(
            insetOne,
            style: CustomTextStyles.titleMediumGray700.copyWith(
              color: appTheme.gray700,
            ),
          ),
        ),
        CustomImageView(
          imagePath: ImageConstant.imgArrowRightGray700,
          height: 12.h,
          width: 8.h,
          margin: EdgeInsets.only(top: 4.h),
        ),
      ],
    );
  }
}
