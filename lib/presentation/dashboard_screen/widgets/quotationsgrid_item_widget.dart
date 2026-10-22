import 'package:flutter/material.dart';
import '../../../core/app_export.dart';

class QuotationsgridItemWidget extends StatelessWidget {
  final String title;
  final String imagePath;

  const QuotationsgridItemWidget({
    Key? key,
    required this.title,
    required this.imagePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: double.maxFinite,
        padding: EdgeInsets.symmetric(vertical: 18.h),
        decoration: AppDecoration.fFFFFFDropShadow.copyWith(
          borderRadius: BorderRadiusStyle.circleBorder12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 6.h),
            CustomImageView(
              imagePath: imagePath,
              height: 62.h,
              width: 62.h,
            ),
            SizedBox(height: 14.h),
            Text(
              title,
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
