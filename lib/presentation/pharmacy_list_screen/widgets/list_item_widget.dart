import 'package:flutter/material.dart';
import '../../../core/app_export.dart';

class ListItemWidget extends StatelessWidget {
  const ListItemWidget({Key? key})
      : super(
          key: key,
        );

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomImageView(
          imagePath: ImageConstant.imgRectangle523,
          height: 60.h,
          width: 60.h,
          radius: BorderRadius.circular(
            3.h,
          ),
          margin: EdgeInsets.only(top: 2.h),
        ),
        Align(
          alignment: Alignment.center,
          child: Container(
            width: 142.h,
            margin: EdgeInsets.only(left: 8.h),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "Goodlife Pharmacy\n",
                    style: theme.textTheme.titleMedium,
                  ),
                  TextSpan(
                    text: "Kenyatta Avenue\n+254 701 747474",
                    style: theme.textTheme.titleSmall,
                  )
                ],
              ),
              textAlign: TextAlign.left,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
      ],
    );
  }
}
