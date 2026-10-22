import 'package:flutter/material.dart';
import '../../../core/app_export.dart';

class List43218andyogItemWidget extends StatelessWidget {
  const List43218andyogItemWidget({Key? key})
      : super(
          key: key,
        );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20.h,
        right: 38.h,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72.h,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "#43218\n",
                    style: theme.textTheme.titleMedium,
                  ),
                  TextSpan(
                    text: "Andy Ogao\nPickup",
                    style: theme.textTheme.titleSmall,
                  )
                ],
              ),
              textAlign: TextAlign.left,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: 12.h),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "  ",
                          ),
                          TextSpan(
                            text: "\$509.40",
                            style: CustomTextStyles.headlineSmallPrimary,
                          )
                        ],
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 24.h),
                    decoration: AppDecoration.fillDeeporangeA200.copyWith(
                      borderRadius: BorderRadiusStyle.roundedBorder8,
                    ),
                    child: Text(
                      "Prepare Order",
                      textAlign: TextAlign.center,
                      style: CustomTextStyles.labelMediumPublicSans,
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
