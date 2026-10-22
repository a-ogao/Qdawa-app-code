import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/appbar_title.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import '../../widgets/custom_elevated_button.dart';

class SubscribeScreen extends StatelessWidget {
  const SubscribeScreen({Key? key})
      : super(
          key: key,
        );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.whiteA700,
      body: SafeArea(
        child: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Container(
              width: double.maxFinite,
              child: Column(
                children: [
                  Container(
                    height: 856.h,
                    width: double.maxFinite,
                    decoration: AppDecoration.fillGray,
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: double.maxFinite,
                          child: _buildTopHeader(context),
                        ),
                        SizedBox(height: 12.h),
                        CustomImageView(
                          imagePath: ImageConstant.imgRectangle159,
                          height: 174.h,
                          width: 184.h,
                          margin: EdgeInsets.only(left: 72.h),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            "QuikDawa Subscription",
                            style: CustomTextStyles.headlineMediumBluegray800,
                          ),
                        ),
                        SizedBox(height: 14.h),
                        _buildSubscriptionDetails(context),
                        SizedBox(height: 50.h),
                        Padding(
                          padding: EdgeInsets.only(left: 70.h),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: "No thanks, ",
                                  style: theme.textTheme.bodyLarge,
                                ),
                                TextSpan(
                                  text: "i will try later",
                                  style: CustomTextStyles.titleMediumPrimary,
                                )
                              ],
                            ),
                            textAlign: TextAlign.left,
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Section Widget
  PreferredSizeWidget _buildTopHeader(BuildContext context) {
    return CustomAppBar(
      leadingWidth: 39.h,
      leading: AppbarLeadingImage(
        imagePath: ImageConstant.imgArrowDown,
        height: 14.h,
        margin: EdgeInsets.only(
          left: 19.h,
          top: 64.h,
          bottom: 22.h,
        ),
      ),
      centerTitle: true,
      title: AppbarTitle(
        text: "Subscribe",
      ),
      styleType: Style.bgFillPrimary,
    );
  }

  /// Section Widget
  Widget _buildSubscriptionDetails(BuildContext context) {
    return Container(
      width: double.maxFinite,
      margin: EdgeInsets.symmetric(horizontal: 18.h),
      padding: EdgeInsets.symmetric(
        horizontal: 12.h,
        vertical: 26.h,
      ),
      decoration: AppDecoration.fillBlue,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 2.h),
          Container(
            width: double.maxFinite,
            margin: EdgeInsets.only(
              left: 14.h,
              right: 8.h,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomImageView(
                  imagePath: ImageConstant.imgBox,
                  height: 36.h,
                  width: 40.h,
                ),
                SizedBox(width: 14.h),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Free Normal Delivery",
                          style: theme.textTheme.titleLarge,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          "Get normal delivery at no extra cost.  Delivery within 12hrs",
                          style: theme.textTheme.bodyMedium,
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
          SizedBox(height: 28.h),
          Container(
            width: double.maxFinite,
            margin: EdgeInsets.only(left: 12.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomImageView(
                  imagePath: ImageConstant.imgTelevision,
                  height: 40.h,
                  width: 44.h,
                ),
                SizedBox(width: 10.h),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Get upto 20% off",
                          style: theme.textTheme.titleLarge,
                        ),
                        Text(
                          "Get upto 20% on selected medicines.",
                          style: theme.textTheme.bodyMedium,
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
          SizedBox(height: 44.h),
          Text(
            "\$9.99/mon",
            style: theme.textTheme.headlineMedium,
          ),
          SizedBox(height: 18.h),
          CustomElevatedButton(
            height: 50.h,
            text: "Subscribe Now",
            margin: EdgeInsets.symmetric(horizontal: 26.h),
            buttonStyle: CustomButtonStyles.fillPrimary,
            buttonTextStyle: CustomTextStyles.titleLargeWhiteA700,
          )
        ],
      ),
    );
  }
}
