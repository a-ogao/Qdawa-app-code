import 'package:flutter/material.dart';
import '../core/app_export.dart';

class AppDecoration {
  // Drop decorations
  static BoxDecoration get dropShadow => BoxDecoration(
        color: theme.colorScheme.primary,
        boxShadow: [
          BoxShadow(
            color: appTheme.gray100,
            spreadRadius: 2.h,
            blurRadius: 2.h,
            offset: Offset(
              0,
              15,
            ),
          )
        ],
      );
// F decorations
  static BoxDecoration get f7F9FA => BoxDecoration(
        color: appTheme.gray5002,
      );
  static BoxDecoration get fFB800 => BoxDecoration(
        color: appTheme.amber600,
      );
  static BoxDecoration get fFE4EE => BoxDecoration(
        color: appTheme.pink50,
      );
  static BoxDecoration get ffffff => BoxDecoration(
        color: appTheme.whiteA700,
      );
  static BoxDecoration get fFFFFFDropShadow => BoxDecoration(
        color: appTheme.whiteA700,
        boxShadow: [
          BoxShadow(
            color: appTheme.gray100,
            spreadRadius: 2.h,
            blurRadius: 2.h,
            offset: Offset(
              0,
              15,
            ),
          )
        ],
      );
// Fill decorations
  static BoxDecoration get fillBlack => BoxDecoration(
        color: appTheme.black900.withOpacity(0.4),
      );
  static BoxDecoration get fillBlue => BoxDecoration(
        color: appTheme.blue50,
      );
  static BoxDecoration get fillDeepOrangeA => BoxDecoration(
        color: appTheme.deepOrangeA400,
      );
  static BoxDecoration get fillDeeporangeA200 => BoxDecoration(
        color: appTheme.deepOrangeA200,
      );
  static BoxDecoration get fillGray => BoxDecoration(
        color: appTheme.gray50,
      );
  static BoxDecoration get fillOnPrimaryContainer => BoxDecoration(
        color: theme.colorScheme.onPrimaryContainer,
      );
  static BoxDecoration get fillPrimary => BoxDecoration(
        color: theme.colorScheme.primary,
      );
  static BoxDecoration get fillRedA => BoxDecoration(
        color: appTheme.redA700,
      );
// Gradient decorations
  static BoxDecoration get gradientBlueGrayEToPrimary => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(0.5, 0),
          end: Alignment(0.5, 1),
          colors: [
            appTheme.blueGray800E5,
            theme.colorScheme.primary.withOpacity(0.9)
          ],
        ),
      );
// Outline decorations
  static BoxDecoration get outlineBlack => BoxDecoration(
        border: Border.all(
          color: appTheme.black900,
          width: 1.h,
        ),
      );
  static BoxDecoration get outlineErrorContainer => BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.errorContainer,
          width: 2.h,
        ),
      );
// Column decorations
  static BoxDecoration get column5 => BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            ImageConstant.imgRectangle97,
          ),
          fit: BoxFit.fill,
        ),
      );
}

class BorderRadiusStyle {
  // Circle borders
  static BorderRadius get circleBorder12 => BorderRadius.circular(
        12.h,
      );
  static BorderRadius get circleBorder40 => BorderRadius.circular(
        40.h,
      );
// Custom borders
  static BorderRadius get customBorderTL10 => BorderRadius.vertical(
        top: Radius.circular(10.h),
      );
  static BorderRadius get customBorderTL30 => BorderRadius.only(
        topLeft: Radius.circular(30.h),
        topRight: Radius.circular(30.h),
        bottomLeft: Radius.circular(10.h),
        bottomRight: Radius.circular(10.h),
      );
  static BorderRadius get customBorderTL301 => BorderRadius.horizontal(
        left: Radius.circular(30.h),
      );
// Rounded borders
  static BorderRadius get roundedBorder24 => BorderRadius.circular(
        24.h,
      );
  static BorderRadius get roundedBorder30 => BorderRadius.circular(
        30.h,
      );
  static BorderRadius get roundedBorder5 => BorderRadius.circular(
        5.h,
      );
  static BorderRadius get roundedBorder8 => BorderRadius.circular(
        8.h,
      );
}
