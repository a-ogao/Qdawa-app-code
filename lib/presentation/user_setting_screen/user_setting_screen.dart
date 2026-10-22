import 'package:flutter/material.dart';
import '../../core/app_export.dart';

class UserSettingScreen extends StatelessWidget {
  const UserSettingScreen({Key? key})
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
              height: SizeUtils.height,
              padding: EdgeInsets.symmetric(
                horizontal: 6.h,
                vertical: 20.h,
              ),
              child: Stack(
                alignment: Alignment.centerRight,
                children: [
                  Container(
                    width: double.maxFinite,
                    margin: EdgeInsets.only(
                      left: 26.h,
                      top: 20.h,
                      bottom: 20.h,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.h,
                      vertical: 36.h,
                    ),
                    decoration: AppDecoration.fillGray.copyWith(
                      borderRadius: BorderRadiusStyle.roundedBorder30,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Spacer(),
                        SizedBox(
                          height: 80.h,
                          width: 82.h,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomImageView(
                                imagePath: ImageConstant.imgEllipse192,
                                height: 80.h,
                                width: 80.h,
                                radius: BorderRadius.circular(
                                  40.h,
                                ),
                              ),
                              CustomImageView(
                                imagePath: ImageConstant.imgBxBxsCamera,
                                height: 24.h,
                                width: 26.h,
                                alignment: Alignment.bottomRight,
                                margin: EdgeInsets.only(right: 8.h),
                              )
                            ],
                          ),
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          "Raduronto Kelax",
                          style: theme.textTheme.titleLarge,
                        ),
                        Text(
                          "ID: 16616e0da38149c2",
                          style: CustomTextStyles.bodyMediumGray800,
                        ),
                        SizedBox(height: 44.h),
                        Container(
                          height: 480.h,
                          width: double.maxFinite,
                          margin: EdgeInsets.only(right: 30.h),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: double.maxFinite,
                                margin: EdgeInsets.only(right: 4.h),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.h,
                                  vertical: 70.h,
                                ),
                                decoration:
                                    AppDecoration.fFFFFFDropShadow.copyWith(
                                  borderRadius:
                                      BorderRadiusStyle.circleBorder12,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Container(
                                      width: double.maxFinite,
                                      margin: EdgeInsets.only(
                                        left: 6.h,
                                        right: 4.h,
                                      ),
                                      child: _buildChangePhoneSection(
                                        context,
                                        qdphoneoneOne:
                                            ImageConstant.imgQdpatient2,
                                        changephoneOne: "Edit Profile",
                                      ),
                                    ),
                                    SizedBox(height: 10.h),
                                    Container(
                                      width: double.maxFinite,
                                      margin: EdgeInsets.only(
                                        left: 6.h,
                                        right: 4.h,
                                      ),
                                      child: _buildChangePhoneSection(
                                        context,
                                        qdphoneoneOne:
                                            ImageConstant.imgQdPhone1,
                                        changephoneOne: "Change Phone Number",
                                      ),
                                    ),
                                    SizedBox(height: 10.h),
                                    Container(
                                      width: double.maxFinite,
                                      margin: EdgeInsets.only(
                                        left: 6.h,
                                        right: 4.h,
                                      ),
                                      child: _buildChangePhoneSection(
                                        context,
                                        qdphoneoneOne:
                                            ImageConstant.imgQdEmail1,
                                        changephoneOne: "Change Email",
                                      ),
                                    ),
                                    SizedBox(height: 10.h),
                                    Container(
                                      width: double.maxFinite,
                                      margin: EdgeInsets.only(
                                        left: 6.h,
                                        right: 4.h,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          CustomImageView(
                                            imagePath:
                                                ImageConstant.imgQdDoctor1,
                                            height: 26.h,
                                            width: 28.h,
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(left: 6.h),
                                            child: Text(
                                              "Support",
                                              style: CustomTextStyles
                                                  .bodyLargeOnPrimary_2,
                                            ),
                                          ),
                                          Spacer(),
                                          CustomImageView(
                                            imagePath:
                                                ImageConstant.imgArrowRight,
                                            height: 12.h,
                                            width: 10.h,
                                            alignment: Alignment.topCenter,
                                            margin: EdgeInsets.only(top: 6.h),
                                          )
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 10.h),
                                    Container(
                                      width: double.maxFinite,
                                      margin: EdgeInsets.only(
                                        left: 6.h,
                                        right: 4.h,
                                      ),
                                      child: _buildSignOutSection(
                                        context,
                                        qdlogoutoneOne:
                                            ImageConstant.imgQdQuote2,
                                        signoutOne: "FAQs",
                                      ),
                                    ),
                                    SizedBox(height: 10.h),
                                    Container(
                                      width: double.maxFinite,
                                      margin: EdgeInsets.only(
                                        left: 6.h,
                                        right: 4.h,
                                      ),
                                      child: _buildSignOutSection(
                                        context,
                                        qdlogoutoneOne:
                                            ImageConstant.imgQdLogout1,
                                        signoutOne: "Sign Out",
                                      ),
                                    ),
                                    SizedBox(height: 10.h),
                                    Container(
                                      width: double.maxFinite,
                                      margin: EdgeInsets.only(left: 10.h),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          CustomImageView(
                                            imagePath:
                                                ImageConstant.imgQdWrong1,
                                            height: 24.h,
                                            width: 26.h,
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(left: 8.h),
                                            child: Text(
                                              "Delete profile/account",
                                              style: CustomTextStyles
                                                  .bodyLargeOnPrimary_2,
                                            ),
                                          ),
                                          Spacer(),
                                          CustomImageView(
                                            imagePath:
                                                ImageConstant.imgArrowRight,
                                            height: 12.h,
                                            width: 10.h,
                                            alignment: Alignment.topCenter,
                                            margin: EdgeInsets.only(top: 4.h),
                                          )
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 102.h)
                                  ],
                                ),
                              ),
                              _buildAccountSettingsSection(context)
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  _buildTopHeaderSection(context)
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Section Widget
  Widget _buildAccountSettingsSection(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: double.maxFinite,
        margin: EdgeInsets.only(left: 4.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.maxFinite,
              padding: EdgeInsets.only(
                left: 20.h,
                top: 12.h,
                bottom: 12.h,
              ),
              decoration: AppDecoration.fillPrimary.copyWith(
                borderRadius: BorderRadiusStyle.customBorderTL10,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Account",
                    style: CustomTextStyles.titleMediumWhiteA700Bold_2,
                  )
                ],
              ),
            ),
            SizedBox(height: 280.h),
            Container(
              width: double.maxFinite,
              padding: EdgeInsets.only(
                left: 20.h,
                top: 12.h,
                bottom: 12.h,
              ),
              decoration: AppDecoration.fFE4EE,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 2.h),
                  Text(
                    "More Settings",
                    style: CustomTextStyles.titleMediumPinkA400,
                  )
                ],
              ),
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.maxFinite,
              child: Opacity(
                opacity: 0.9,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.h),
                  child: Row(
                    children: [
                      CustomImageView(
                        imagePath: ImageConstant.imgLocation,
                        height: 20.h,
                        width: 20.h,
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 6.h),
                        child: Text(
                          "Change Password",
                          style: CustomTextStyles.bodyLargeOnPrimary_2,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  /// Section Widget
  Widget _buildTopHeaderSection(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        margin: EdgeInsets.symmetric(horizontal: 14.h),
        color: theme.colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusStyle.customBorderTL30,
        ),
        child: Container(
          height: 100.h,
          padding: EdgeInsets.only(
            left: 18.h,
            right: 18.h,
            bottom: 20.h,
          ),
          decoration: AppDecoration.fillPrimary.copyWith(
            borderRadius: BorderRadiusStyle.customBorderTL30,
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              CustomImageView(
                imagePath: ImageConstant.imgQdNotification,
                height: 30.h,
                width: 30.h,
                alignment: Alignment.bottomRight,
                margin: EdgeInsets.only(right: 36.h),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.maxFinite,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CustomImageView(
                          imagePath: ImageConstant.imgArrowDown,
                          height: 14.h,
                          width: 22.h,
                        ),
                        Spacer(
                          flex: 55,
                        ),
                        Text(
                          "Profile",
                          style: CustomTextStyles.titleMediumWhiteA700Bold,
                        ),
                        Spacer(
                          flex: 44,
                        ),
                        Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            width: 14.h,
                            height: 12.h,
                            alignment: Alignment.center,
                            decoration: AppDecoration.fillRedA.copyWith(
                              borderRadius: BorderRadiusStyle.roundedBorder5,
                            ),
                            child: Text(
                              "8",
                              textAlign: TextAlign.center,
                              style: theme.textTheme.labelMedium,
                            ),
                          ),
                        ),
                        CustomImageView(
                          imagePath: ImageConstant.imgImage49,
                          height: 24.h,
                          width: 26.h,
                          radius: BorderRadius.circular(
                            12.h,
                          ),
                          margin: EdgeInsets.only(
                            left: 4.h,
                            top: 10.h,
                          ),
                        )
                      ],
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  /// Common widget
  Widget _buildSignOutSection(
    BuildContext context, {
    required String qdlogoutoneOne,
    required String signoutOne,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CustomImageView(
          imagePath: qdlogoutoneOne,
          height: 24.h,
          width: 26.h,
        ),
        Padding(
          padding: EdgeInsets.only(left: 6.h),
          child: Text(
            signoutOne,
            style: CustomTextStyles.bodyLargeOnPrimary_2.copyWith(
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ),
        Spacer(),
        CustomImageView(
          imagePath: ImageConstant.imgArrowRight,
          height: 12.h,
          width: 10.h,
          alignment: Alignment.topCenter,
          margin: EdgeInsets.only(top: 4.h),
        )
      ],
    );
  }

  /// Common widget
  Widget _buildChangePhoneSection(
    BuildContext context, {
    required String qdphoneoneOne,
    required String changephoneOne,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CustomImageView(
          imagePath: qdphoneoneOne,
          height: 24.h,
          width: 26.h,
        ),
        Padding(
          padding: EdgeInsets.only(left: 6.h),
          child: Text(
            changephoneOne,
            style: CustomTextStyles.bodyLargeOnPrimary_2.copyWith(
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ),
        Spacer(),
        CustomImageView(
          imagePath: ImageConstant.imgArrowRight,
          height: 12.h,
          width: 10.h,
          alignment: Alignment.topCenter,
          margin: EdgeInsets.only(top: 4.h),
        )
      ],
    );
  }
}
