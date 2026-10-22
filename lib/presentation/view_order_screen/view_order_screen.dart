import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_text_form_field.dart';

// ignore_for_file: must_be_immutable
class ViewOrderScreen extends StatelessWidget {
  ViewOrderScreen({Key? key})
      : super(
          key: key,
        );

  TextEditingController toponeController = TextEditingController();

  TextEditingController pymentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.whiteA700,
      body: SafeArea(
        child: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Container(
              height: 1016.h,
              padding: EdgeInsets.symmetric(
                horizontal: 12.h,
                vertical: 20.h,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: double.maxFinite,
                    padding: EdgeInsets.symmetric(horizontal: 6.h),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.maxFinite,
                          padding: EdgeInsets.only(
                            left: 16.h,
                            top: 30.h,
                            right: 16.h,
                          ),
                          decoration: AppDecoration.fillGray.copyWith(
                            borderRadius: BorderRadiusStyle.roundedBorder30,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: 94.h),
                              Padding(
                                padding: EdgeInsets.only(right: 6.h),
                                child: CustomTextFormField(
                                  controller: toponeController,
                                  hintText: "Order #43218",
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20.h,
                                    vertical: 14.h,
                                  ),
                                  borderDecoration:
                                      TextFormFieldStyleHelper.fillPrimary,
                                  fillColor: theme.colorScheme.primary,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              _buildOrderSummary(context),
                              SizedBox(height: 34.h),
                              _buildPaymentStatus(context)
                            ],
                          ),
                        ),
                        SizedBox(height: 34.h),
                        CustomElevatedButton(
                          text: "Ready to Dispatch",
                          margin: EdgeInsets.only(
                            left: 32.h,
                            right: 30.h,
                          ),
                          rightIcon: Container(
                            margin: EdgeInsets.only(left: 30.h),
                            child: CustomImageView(
                              imagePath: ImageConstant.imgArrowrightGray5003,
                              height: 24.h,
                              width: 24.h,
                              fit: BoxFit.contain,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  _buildTopHeader(context)
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Section Widget
  Widget _buildOrderSummary(BuildContext context) {
    return Container(
      width: double.maxFinite,
      margin: EdgeInsets.only(right: 6.h),
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
              priceOne: "\$280",
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
              priceOne: "\$208",
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
                    children: [],
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
    );
  }

  /// Section Widget
  Widget _buildPaymentStatus(BuildContext context) {
    return Container(
      height: 286.h,
      width: double.maxFinite,
      margin: EdgeInsets.only(right: 6.h),
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
                  CustomTextFormField(
                    controller: pymentController,
                    hintText: "Pyment Status: Paid",
                    textInputAction: TextInputAction.done,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20.h,
                      vertical: 14.h,
                    ),
                    borderDecoration: TextFormFieldStyleHelper.fillPrimary,
                    fillColor: theme.colorScheme.primary,
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
                  child: _buildTransactionId(
                    context,
                    transactionid: "Payment Method",
                    aggd7498jfOne: "Mobile",
                  ),
                ),
                SizedBox(height: 10.h),
                Container(
                  width: double.maxFinite,
                  margin: EdgeInsets.symmetric(horizontal: 2.h),
                  child: _buildTransactionId(
                    context,
                    transactionid: "Transaction ID",
                    aggd7498jfOne: "#AGGD7498JF",
                  ),
                ),
                SizedBox(height: 12.h),
                Container(
                  width: double.maxFinite,
                  margin: EdgeInsets.only(right: 4.h),
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
                        text: "If haveing any transaction issue, Please\n",
                        style: theme.textTheme.bodyLarge,
                      ),
                      TextSpan(
                        text: "conatat us",
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
    );
  }

  /// Section Widget
  Widget _buildTopHeader(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        margin: EdgeInsets.symmetric(horizontal: 8.h),
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

  /// Common widget
  Widget _buildItemRowTwo(
    BuildContext context, {
    required String twoOne,
    required String weightOne,
    required String oneTwo,
    required String priceOne,
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
          priceOne,
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
  Widget _buildTransactionId(
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
