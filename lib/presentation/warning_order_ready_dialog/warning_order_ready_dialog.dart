import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/custom_elevated_button.dart'; // ignore_for_file: must_be_immutable

class WarningOrderReadyDialog extends StatelessWidget {
  const WarningOrderReadyDialog({Key? key})
      : super(
          key: key,
        );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.maxFinite,
          padding: EdgeInsets.symmetric(
            horizontal: 6.h,
            vertical: 8.h,
          ),
          decoration: AppDecoration.ffffff.copyWith(
            borderRadius: BorderRadiusStyle.roundedBorder5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomImageView(
                imagePath: ImageConstant.imgCloseGray900,
                height: 24.h,
                width: 26.h,
                alignment: Alignment.centerRight,
                onTap: () {
                  onTapImgCloseone(context);
                },
              ),
              SizedBox(height: 8.h),
              CustomImageView(
                imagePath: ImageConstant.imgQdCorrect2,
                height: 62.h,
                width: 64.h,
              ),
              SizedBox(height: 20.h),
              Text(
                "Confirm order is ready for delivery",
                style: theme.textTheme.titleMedium,
              ),
              SizedBox(height: 6.h),
              SizedBox(
                width: double.maxFinite,
                child: Divider(
                  color: appTheme.blueGray800B2,
                  indent: 22.h,
                  endIndent: 22.h,
                ),
              ),
              SizedBox(height: 60.h),
              Container(
                height: 62.h,
                width: double.maxFinite,
                margin: EdgeInsets.only(
                  left: 18.h,
                  right: 8.h,
                ),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Text(
                      "Done",
                      style: CustomTextStyles.titleMediumWhiteA700Bold_1,
                    ),
                    CustomElevatedButton(
                      text: "Yes, Ready to Dispatch",
                      alignment: Alignment.topCenter,
                    )
                  ],
                ),
              ),
              SizedBox(height: 6.h)
            ],
          ),
        )
      ],
    );
  }

  /// Navigates back to the previous screen.
  onTapImgCloseone(BuildContext context) {
    Navigator.pop(context);
  }
}
