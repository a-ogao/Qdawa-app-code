import 'package:flutter/material.dart';
import '../core/app_export.dart';

extension on TextStyle {
  TextStyle get publicSans {
    return copyWith(
      fontFamily: 'Public Sans',
    );
  }
}

/// A collection of pre-defined text styles for customizing text appearance,
/// categorized by different font families and weights.
/// Additionally, this class includes extensions on [TextStyle] to easily apply specific font families to text.
class CustomTextStyles {
  // Body text style
  static TextStyle get bodyLargeGray400 => theme.textTheme.bodyLarge!.copyWith(
        color: appTheme.gray400,
      );
  static TextStyle get bodyLargeGray5001 => theme.textTheme.bodyLarge!.copyWith(
        color: appTheme.gray5001,
      );
  static TextStyle get bodyLargeGray600 => theme.textTheme.bodyLarge!.copyWith(
        color: appTheme.gray600,
      );
  static TextStyle get bodyLargeGray700 => theme.textTheme.bodyLarge!.copyWith(
        color: appTheme.gray700,
      );
  static TextStyle get bodyLargeOnErrorContainer =>
      theme.textTheme.bodyLarge!.copyWith(
        color: theme.colorScheme.onErrorContainer,
      );
  static TextStyle get bodyLargeOnPrimary =>
      theme.textTheme.bodyLarge!.copyWith(
        color: theme.colorScheme.onPrimary,
      );
  static TextStyle get bodyLargeOnPrimary_1 =>
      theme.textTheme.bodyLarge!.copyWith(
        color: theme.colorScheme.onPrimary,
      );
  static TextStyle get bodyLargeOnPrimary_2 =>
      theme.textTheme.bodyLarge!.copyWith(
        color: theme.colorScheme.onPrimary,
      );
  static TextStyle get bodyLargePrimary => theme.textTheme.bodyLarge!.copyWith(
        color: theme.colorScheme.primary,
      );
  static TextStyle get bodyLargePrimary_1 =>
      theme.textTheme.bodyLarge!.copyWith(
        color: theme.colorScheme.primary,
      );
  static TextStyle get bodyLargeWhiteA700 =>
      theme.textTheme.bodyLarge!.copyWith(
        color: appTheme.whiteA700,
      );
  static TextStyle get bodyMediumGray800 =>
      theme.textTheme.bodyMedium!.copyWith(
        color: appTheme.gray800,
      );
// Display text style
  static TextStyle get displayMediumExtraBold =>
      theme.textTheme.displayMedium!.copyWith(
        fontSize: 48.fSize,
        fontWeight: FontWeight.w800,
      );
// Headline text style
  static TextStyle get headlineMediumBluegray800 =>
      theme.textTheme.headlineMedium!.copyWith(
        color: appTheme.blueGray800,
      );
  static TextStyle get headlineSmallGray700 =>
      theme.textTheme.headlineSmall!.copyWith(
        color: appTheme.gray700,
      );
  static TextStyle get headlineSmallPrimary =>
      theme.textTheme.headlineSmall!.copyWith(
        color: theme.colorScheme.primary,
      );
  static TextStyle get headlineSmallPrimarySemiBold =>
      theme.textTheme.headlineSmall!.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w600,
      );
  static TextStyle get headlineSmallSemiBold =>
      theme.textTheme.headlineSmall!.copyWith(
        fontWeight: FontWeight.w600,
      );
  static TextStyle get headlineSmallSemiBold_1 =>
      theme.textTheme.headlineSmall!.copyWith(
        fontWeight: FontWeight.w600,
      );
  static TextStyle get headlineSmallWhiteA700 =>
      theme.textTheme.headlineSmall!.copyWith(
        color: appTheme.whiteA700,
        fontWeight: FontWeight.w700,
      );
// Label text style
  static TextStyle get labelLargeBlack900 =>
      theme.textTheme.labelLarge!.copyWith(
        color: appTheme.black900,
      );
  static get labelMediumPublicSans => theme.textTheme.labelMedium!.publicSans;
  static TextStyle get labelMediumPublicSansGray70001 =>
      theme.textTheme.labelMedium!.publicSans.copyWith(
        color: appTheme.gray70001,
      );
// Title text style
  static TextStyle get titleLargeOnPrimary =>
      theme.textTheme.titleLarge!.copyWith(
        color: theme.colorScheme.onPrimary,
        fontWeight: FontWeight.w600,
      );
  static TextStyle get titleLargeOnPrimaryMedium =>
      theme.textTheme.titleLarge!.copyWith(
        color: theme.colorScheme.onPrimary,
        fontWeight: FontWeight.w500,
      );
  static TextStyle get titleLargeOnPrimarySemiBold =>
      theme.textTheme.titleLarge!.copyWith(
        color: theme.colorScheme.onPrimary,
        fontWeight: FontWeight.w600,
      );
  static TextStyle get titleLargeOnPrimarySemiBold_1 =>
      theme.textTheme.titleLarge!.copyWith(
        color: theme.colorScheme.onPrimary,
        fontWeight: FontWeight.w600,
      );
  static TextStyle get titleLargePrimary =>
      theme.textTheme.titleLarge!.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w600,
      );
  static TextStyle get titleLargeSemiBold =>
      theme.textTheme.titleLarge!.copyWith(
        fontWeight: FontWeight.w600,
      );
  static TextStyle get titleLargeWhiteA700 =>
      theme.textTheme.titleLarge!.copyWith(
        color: appTheme.whiteA700,
      );
  static TextStyle get titleLargeWhiteA700Medium =>
      theme.textTheme.titleLarge!.copyWith(
        color: appTheme.whiteA700,
        fontWeight: FontWeight.w500,
      );
  static TextStyle get titleMediumBlack900 =>
      theme.textTheme.titleMedium!.copyWith(
        color: appTheme.black900,
      );
  static TextStyle get titleMediumBold => theme.textTheme.titleMedium!.copyWith(
        fontWeight: FontWeight.w700,
      );
  static TextStyle get titleMediumBold17 =>
      theme.textTheme.titleMedium!.copyWith(
        fontSize: 17.fSize,
        fontWeight: FontWeight.w700,
      );
  static TextStyle get titleMediumDeeppurpleA700 =>
      theme.textTheme.titleMedium!.copyWith(
        color: appTheme.deepPurpleA700,
        fontSize: 18.fSize,
      );
  static TextStyle get titleMediumGray700 =>
      theme.textTheme.titleMedium!.copyWith(
        color: appTheme.gray700,
      );
  static TextStyle get titleMediumGray800 =>
      theme.textTheme.titleMedium!.copyWith(
        color: appTheme.gray800,
      );
  static TextStyle get titleMediumGreenA700 =>
      theme.textTheme.titleMedium!.copyWith(
        color: appTheme.greenA700,
      );
  static TextStyle get titleMediumOnError =>
      theme.textTheme.titleMedium!.copyWith(
        color: theme.colorScheme.onError,
        fontSize: 18.fSize,
      );
  static TextStyle get titleMediumOnErrorContainer =>
      theme.textTheme.titleMedium!.copyWith(
        color: theme.colorScheme.onErrorContainer,
      );
  static TextStyle get titleMediumOnErrorContainer_1 =>
      theme.textTheme.titleMedium!.copyWith(
        color: theme.colorScheme.onErrorContainer,
      );
  static TextStyle get titleMediumPinkA400 =>
      theme.textTheme.titleMedium!.copyWith(
        color: appTheme.pinkA400,
        fontWeight: FontWeight.w700,
      );
  static TextStyle get titleMediumPinkA40018 =>
      theme.textTheme.titleMedium!.copyWith(
        color: appTheme.pinkA400,
        fontSize: 18.fSize,
      );
  static TextStyle get titleMediumPinkA400Bold =>
      theme.textTheme.titleMedium!.copyWith(
        color: appTheme.pinkA400,
        fontWeight: FontWeight.w700,
      );
  static TextStyle get titleMediumPrimary =>
      theme.textTheme.titleMedium!.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w600,
      );
  static TextStyle get titleMediumPrimary18 =>
      theme.textTheme.titleMedium!.copyWith(
        color: theme.colorScheme.primary,
        fontSize: 18.fSize,
      );
  static TextStyle get titleMediumPrimaryBold =>
      theme.textTheme.titleMedium!.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w700,
      );
  static TextStyle get titleMediumPrimary_1 =>
      theme.textTheme.titleMedium!.copyWith(
        color: theme.colorScheme.primary,
      );
  static TextStyle get titleMediumSemiBold =>
      theme.textTheme.titleMedium!.copyWith(
        fontWeight: FontWeight.w600,
      );
  static TextStyle get titleMediumWhiteA700 =>
      theme.textTheme.titleMedium!.copyWith(
        color: appTheme.whiteA700,
      );
  static TextStyle get titleMediumWhiteA700Bold =>
      theme.textTheme.titleMedium!.copyWith(
        color: appTheme.whiteA700,
        fontSize: 17.fSize,
        fontWeight: FontWeight.w700,
      );
  static TextStyle get titleMediumWhiteA700Bold18 =>
      theme.textTheme.titleMedium!.copyWith(
        color: appTheme.whiteA700,
        fontSize: 18.fSize,
        fontWeight: FontWeight.w700,
      );
  static TextStyle get titleMediumWhiteA700Bold_1 =>
      theme.textTheme.titleMedium!.copyWith(
        color: appTheme.whiteA700,
        fontWeight: FontWeight.w700,
      );
  static TextStyle get titleMediumWhiteA700Bold_2 =>
      theme.textTheme.titleMedium!.copyWith(
        color: appTheme.whiteA700,
        fontWeight: FontWeight.w700,
      );
  static TextStyle get titleMediumWhiteA700SemiBold =>
      theme.textTheme.titleMedium!.copyWith(
        color: appTheme.whiteA700,
        fontWeight: FontWeight.w600,
      );
  static TextStyle get titleSmallPrimary =>
      theme.textTheme.titleSmall!.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w700,
      );
  static TextStyle get titleSmallWhiteA700 =>
      theme.textTheme.titleSmall!.copyWith(
        color: appTheme.whiteA700,
      );
}
