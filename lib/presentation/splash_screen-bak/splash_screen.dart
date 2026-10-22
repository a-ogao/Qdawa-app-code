import 'package:flutter/material.dart';
import '../../core/app_export.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key})
      : super(
          key: key,
        );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.whiteA700,
      body: SafeArea(
        child: Container(
          width: double.maxFinite,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.maxFinite,
                  padding: EdgeInsets.symmetric(vertical: 34.h),
                  decoration: AppDecoration.gradientBlueGrayEToPrimary,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Spacer(
                        flex: 40,
                      ),
                      SizedBox(
                        height: 302.h,
                        width: 336.h,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Text(
                              "QuikDawa",
                              style: CustomTextStyles.displayMediumExtraBold,
                            ),
                            CustomImageView(
                              imagePath: ImageConstant.imgRectangle159,
                              height: 174.h,
                              width: 184.h,
                              alignment: Alignment.topCenter,
                            )
                          ],
                        ),
                      ),
                      Spacer(
                        flex: 59,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20), // Adds horizontal margin
                        child: Text(
                          "Copyright © QuikDawa 2024. All Rights Reserved.",
                          style: CustomTextStyles.bodyLargeGray5001,
                          textAlign: TextAlign.center, // Center aligns text
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
