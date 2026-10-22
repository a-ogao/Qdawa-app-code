import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_button.dart';

class ActiongridItemWidget extends StatelessWidget {
  const ActiongridItemWidget({Key? key})
      : super(
          key: key,
        );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.symmetric(vertical: 18.h),
      decoration: AppDecoration.fFFFFFDropShadow.copyWith(
        borderRadius: BorderRadiusStyle.circleBorder12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 4.h),
          CustomIconButton(
            height: 60.h,
            width: 60.h,
            padding: EdgeInsets.all(12.h),
            decoration: IconButtonStyleHelper.fillPrimary,
            child: CustomImageView(
              imagePath: ImageConstant.imgTelevisionWhiteA70060x60,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            "Withdraw",
            style: theme.textTheme.titleMedium,
          )
        ],
      ),
    );
  }
}
