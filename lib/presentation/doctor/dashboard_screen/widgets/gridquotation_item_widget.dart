import 'package:flutter/material.dart';
import '../../../../core/app_export.dart';

class GridquotationItemWidget extends StatelessWidget {
  final String title;
  final int? count; // Optional count parameter

  const GridquotationItemWidget({
    Key? key,
    required this.title,
    this.count,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.only(
        left: 20.h,
        top: 12.h,
        bottom: 12.h,
      ),
      decoration: AppDecoration.fFFFFFDropShadow.copyWith(
        borderRadius: BorderRadiusStyle.roundedBorder5,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title, // Dynamically display the title
            style: theme.textTheme.titleMedium,
          ),
          if (count != null) // Display the count only if it's provided
            Text(
              "$count",
              style: CustomTextStyles.titleMediumPrimary18,
            ),
        ],
      ),
    );
  }
}
