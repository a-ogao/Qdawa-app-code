import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_text_form_field.dart';

// ignore_for_file: must_be_immutable
class ViewOrderThreeScreen extends StatelessWidget {
  ViewOrderThreeScreen({Key? key})
      : super(
          key: key,
        );

  TextEditingController toponeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.whiteA700,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Container(
              width: double.maxFinite,
              padding: EdgeInsets.only(
                left: 12.h,
                top: 20.h,
                right: 12.h,
              ),
              child: Column(
                children: [
                  Container(
                    height: 964.h,
                    width: double.maxFinite,
                    margin: EdgeInsets.only(right: 6.h),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            height: 858.h,
                            width: 374.h,
                            margin: EdgeInsets.only(top: 8.h),
                            decoration: BoxDecoration(
                              color: appTheme.gray50,
                              borderRadius: BorderRadius.circular(
                                30.h,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          height: 964.h,
                          margin: EdgeInsets.only(left: 6.h),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomElevatedButton(
                                width: 310.h,
                                text: "Enter pickup OTP",
                                margin: EdgeInsets.only(
                                  left: 18.h,
                                  bottom: 24.h,
                                ),
                                alignment: Alignment.bottomLeft,
                              ),
                              Container(
                                width: double.maxFinite,
                                decoration: AppDecoration.fillBlack.copyWith(
                                  borderRadius:
                                      BorderRadiusStyle.roundedBorder24,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildTopHeader(context),
                                    SizedBox(height: 34.h),
                                    Container(
                                      height: 702.h,
                                      width: double.maxFinite,
                                      margin: EdgeInsets.only(
                                        left: 14.h,
                                        right: 22.h,
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          _buildPaymentStatusSection(context),
                                          _buildOrderDetailsSection(context),
                                          _buildOtpEntrySection(context)
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 96.h),
                                    CustomImageView(
                                      imagePath: ImageConstant.imgCopy,
                                      height: 26.h,
                                      width: 24.h,
                                      alignment: Alignment.centerRight,
                                      margin: EdgeInsets.only(right: 52.h),
                                    ),
                                    SizedBox(height: 2.h)
                                  ],
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h)
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Section Widget
  Widget _buildTopHeader(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        margin: EdgeInsets.zero,
        color: theme.colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusStyle.customBorderTL30,
        ),
        child: Container(
          height: 100.h,
          width: double.maxFinite,
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
                margin: EdgeInsets.only(right: 30.h),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.maxFinite,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomImageView(
                          imagePath: ImageConstant.imgArrowDown,
                          height: 10.h,
                          width: 22.h,
                          margin: EdgeInsets.only(top: 10.h),
                        ),
                        Spacer(
                          flex: 54,
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Text(
                            "View Order",
                            style: CustomTextStyles.titleMediumWhiteA700Bold,
                          ),
                        ),
                        Spacer(
                          flex: 45,
                        ),
                        Container(
                          width: 14.h,
                          height: 12.h,
                          alignment: Alignment.center,
                          decoration: AppDecoration.fillRedA.copyWith(
                            borderRadius: BorderRadiusStyle.roundedBorder8,
                          ),
                          child: Text(
                            "8",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelMedium,
                          ),
                        ),
                        CustomImageView(
                          imagePath: ImageConstant.imgImage49,
                          height: 24.h,
                          width: 26.h,
                          radius: BorderRadius.circular(
                            12.h,
                          ),
                          alignment: Alignment.bottomCenter,
                          margin: EdgeInsets.only(top: 12.h),
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

  /// Section Widget
  Widget _buildPaymentStatusSection(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 286.h,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: double.maxFinite,
                      padding: EdgeInsets.only(
                        left: 20.h,
                        top: 12.h,
                        bottom: 12.h,
                      ),
                      decoration: AppDecoration.fillPrimary,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Pyment Status: Paid",
                            style:
                                CustomTextStyles.titleMediumWhiteA700SemiBold,
                          )
                        ],
                      ),
                    ),
                    SizedBox(height: 34.h),
                    CustomImageView(
                      imagePath: ImageConstant.imgCheckmark,
                      height: 14.h,
                      width: 20.h,
                      margin: EdgeInsets.only(right: 20.h),
                    )
                  ],
                ),
              ),
            ),
            Container(
              width: double.maxFinite,
              padding: EdgeInsets.symmetric(horizontal: 16.h),
              decoration: AppDecoration.ffffff,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 16.h),
                  Container(
                    width: double.maxFinite,
                    margin: EdgeInsets.only(right: 4.h),
                    child: _buildTransactionIdRow(
                      context,
                      transactionid: "Payment Method",
                      aggd7498jfOne: "Mobile",
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    width: double.maxFinite,
                    margin: EdgeInsets.symmetric(horizontal: 2.h),
                    child: _buildTransactionIdRow(
                      context,
                      transactionid: "Transaction ID",
                      aggd7498jfOne: "#AGGD7498JF",
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    width: double.maxFinite,
                    margin: EdgeInsets.only(right: 2.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Transaction Date",
                          style: CustomTextStyles.titleMediumGray800,
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Text(
                            "05-Dec-2024 16:18:38",
                            style: theme.textTheme.labelLarge,
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    width: double.maxFinite,
                    margin: EdgeInsets.only(
                      left: 2.h,
                      right: 4.h,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total Amounts      ",
                          style: CustomTextStyles.titleMediumGray800,
                        ),
                        Text(
                          "\$509.40",
                          style: CustomTextStyles.titleMediumGray800,
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 36.h),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "If have any transaction issue, Please\n",
                          style: theme.textTheme.bodyLarge,
                        ),
                        TextSpan(
                          text: "contact us",
                          style: CustomTextStyles.bodyLargePrimary,
                        )
                      ],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  /// Section Widget
  Widget _buildOrderDetailsSection(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextFormField(
              controller: toponeController,
              hintText: "Order #43218",
              textInputAction: TextInputAction.done,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20.h,
                vertical: 14.h,
              ),
              borderDecoration: TextFormFieldStyleHelper.fillPrimary,
              fillColor: theme.colorScheme.primary,
            ),
            SizedBox(height: 4.h),
            Container(
              width: double.maxFinite,
              padding: EdgeInsets.symmetric(vertical: 8.h),
              decoration: AppDecoration.fFFFFFDropShadow.copyWith(
                borderRadius: BorderRadiusStyle.roundedBorder5,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 6.h),
                  SizedBox(
                    width: double.maxFinite,
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.maxFinite,
                          child: Row(
                            children: [
                              Text(
                                "Sr.",
                                style: theme.textTheme.titleMedium,
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 22.h),
                                child: Text(
                                  "Item Name",
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                              Spacer(),
                              Text(
                                "\tQty",
                                style: theme.textTheme.titleMedium,
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                  left: 18.h,
                                  right: 34.h,
                                ),
                                child: Text(
                                  "Amount",
                                  style: theme.textTheme.titleMedium,
                                ),
                              )
                            ],
                          ),
                        ),
                        SizedBox(height: 20.h),
                        SizedBox(
                          width: double.maxFinite,
                          child: Divider(),
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Container(
                    width: double.maxFinite,
                    margin: EdgeInsets.symmetric(horizontal: 6.h),
                    child: _buildItemRowTwo(
                      context,
                      twoOne: "1",
                      weightOne: "Betaloc 100 mg",
                      oneTwo: "1",
                      priceTwo: "\$280",
                    ),
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.maxFinite,
                    child: Divider(),
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    width: double.maxFinite,
                    margin: EdgeInsets.symmetric(horizontal: 6.h),
                    child: _buildItemRowTwo(
                      context,
                      twoOne: "2",
                      weightOne: "Dorzolamide 10 mg",
                      oneTwo: "1",
                      priceTwo: "\$208",
                    ),
                  ),
                  SizedBox(height: 22.h),
                  SizedBox(
                    width: double.maxFinite,
                    child: Divider(),
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    width: double.maxFinite,
                    margin: EdgeInsets.only(
                      left: 40.h,
                      right: 50.h,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: EdgeInsets.only(top: 6.h),
                            child: Text(
                              "Tax",
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                        ),
                        Text(
                          "\$9.40",
                          style: theme.textTheme.titleSmall,
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 14.h),
                  SizedBox(
                    width: double.maxFinite,
                    child: Divider(),
                  ),
                  SizedBox(height: 8.h),
                  SizedBox(
                    height: 66.h,
                    width: double.maxFinite,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: EdgeInsets.only(right: 68.h),
                            child: Text(
                              "       \$2",
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: double.maxFinite,
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(left: 40.h),
                                child: Text(
                                  "Delivery Service",
                                  style: theme.textTheme.titleSmall,
                                ),
                              ),
                              SizedBox(height: 44.h),
                              SizedBox(
                                width: double.maxFinite,
                                child: Divider(
                                  color: appTheme.gray300,
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    width: double.maxFinite,
                    margin: EdgeInsets.only(
                      left: 40.h,
                      right: 32.h,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total",
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          "\$509.40",
                          style: theme.textTheme.titleSmall,
                        )
                      ],
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  /// Section Widget
  Widget _buildOtpEntrySection(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.symmetric(
        horizontal: 8.h,
        vertical: 14.h,
      ),
      decoration: AppDecoration.ffffff.copyWith(
        borderRadius: BorderRadiusStyle.roundedBorder5,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 4.h),
          CustomImageView(
            imagePath: ImageConstant.imgCloseGray900,
            height: 24.h,
            width: 26.h,
            alignment: Alignment.centerRight,
            margin: EdgeInsets.only(right: 2.h),
          ),
          SizedBox(height: 10.h),
          Text(
            "Enter Pickup OTP",
            style: CustomTextStyles.titleLargeOnPrimaryMedium,
          ),
          SizedBox(height: 40.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.h,
                  vertical: 4.h,
                ),
                decoration: AppDecoration.fFFFFFDropShadow.copyWith(
                  borderRadius: BorderRadiusStyle.roundedBorder5,
                ),
                child: Text(
                  "4",
                  textAlign: TextAlign.left,
                  style: CustomTextStyles.headlineSmallPrimarySemiBold,
                ),
              ),
              SizedBox(width: 10.h),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.h,
                  vertical: 8.h,
                ),
                decoration: AppDecoration.fFFFFFDropShadow.copyWith(
                  borderRadius: BorderRadiusStyle.roundedBorder5,
                ),
                child: Text(
                  "-",
                  textAlign: TextAlign.center,
                  style: CustomTextStyles.headlineSmallPrimarySemiBold,
                ),
              ),
              SizedBox(width: 10.h),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.h,
                  vertical: 4.h,
                ),
                decoration: AppDecoration.fFFFFFDropShadow.copyWith(
                  borderRadius: BorderRadiusStyle.roundedBorder5,
                ),
                child: Text(
                  "-",
                  textAlign: TextAlign.center,
                  style: CustomTextStyles.headlineSmallPrimarySemiBold,
                ),
              ),
              SizedBox(width: 10.h),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.h,
                  vertical: 4.h,
                ),
                decoration: AppDecoration.fFFFFFDropShadow.copyWith(
                  borderRadius: BorderRadiusStyle.roundedBorder5,
                ),
                child: Text(
                  "-",
                  textAlign: TextAlign.center,
                  style: CustomTextStyles.headlineSmallPrimarySemiBold,
                ),
              ),
              SizedBox(width: 10.h),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.h,
                  vertical: 2.h,
                ),
                decoration: AppDecoration.fFFFFFDropShadow.copyWith(
                  borderRadius: BorderRadiusStyle.roundedBorder5,
                ),
                child: Text(
                  "-",
                  textAlign: TextAlign.center,
                  style: CustomTextStyles.headlineSmallPrimarySemiBold,
                ),
              ),
              SizedBox(width: 10.h),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.h,
                  vertical: 8.h,
                ),
                decoration: AppDecoration.fFFFFFDropShadow.copyWith(
                  borderRadius: BorderRadiusStyle.roundedBorder5,
                ),
                child: Text(
                  "6",
                  textAlign: TextAlign.center,
                  style: CustomTextStyles.headlineSmallPrimarySemiBold,
                ),
              )
            ],
          ),
          SizedBox(height: 44.h),
          Container(
            height: 62.h,
            width: double.maxFinite,
            margin: EdgeInsets.only(
              left: 16.h,
              right: 6.h,
            ),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Text(
                  "Done",
                  style: CustomTextStyles.titleMediumWhiteA700Bold_1,
                ),
                CustomElevatedButton(
                  text: "Submit ",
                  alignment: Alignment.topCenter,
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  /// Common widget
  Widget _buildItemRowTwo(
    BuildContext context, {
    required String twoOne,
    required String weightOne,
    required String oneTwo,
    required String priceTwo,
  }) {
    return Row(
      children: [
        Text(
          twoOne,
          style: theme.textTheme.titleSmall!.copyWith(
            color: appTheme.gray700,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 26.h),
          child: Text(
            weightOne,
            style: theme.textTheme.titleSmall!.copyWith(
              color: appTheme.gray700,
            ),
          ),
        ),
        Spacer(
          flex: 29,
        ),
        Text(
          oneTwo,
          style: theme.textTheme.titleSmall!.copyWith(
            color: appTheme.gray700,
          ),
        ),
        Spacer(
          flex: 31,
        ),
        Text(
          priceTwo,
          style: theme.textTheme.titleSmall!.copyWith(
            color: appTheme.gray700,
          ),
        ),
        Spacer(
          flex: 39,
        )
      ],
    );
  }

  /// Common widget
  Widget _buildTransactionIdRow(
    BuildContext context, {
    required String transactionid,
    required String aggd7498jfOne,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          transactionid,
          style: CustomTextStyles.titleMediumGray800.copyWith(
            color: appTheme.gray800,
          ),
        ),
        Text(
          aggd7498jfOne,
          style: CustomTextStyles.titleMediumGray800.copyWith(
            color: appTheme.gray800,
          ),
        )
      ],
    );
  }
}
