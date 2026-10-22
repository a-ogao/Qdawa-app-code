import 'package:flutter/material.dart';
import '../core/app_export.dart';

String _appTheme = "lightCode";
LightCodeColors get appTheme => ThemeHelper().themeColor();
ThemeData get theme => ThemeHelper().themeData();

/// Helper class for managing themes and colors.

// ignore_for_file: must_be_immutable
class ThemeHelper {
  // A map of custom color themes supported by the app
  Map<String, LightCodeColors> _supportedCustomColor = {
    'lightCode': LightCodeColors()
  };

// A map of color schemes supported by the app
  Map<String, ColorScheme> _supportedColorScheme = {
    'lightCode': ColorSchemes.lightCodeColorScheme
  };

  /// Changes the app theme to [_newTheme].
  void changeTheme(String _newTheme) {
    _appTheme = _newTheme;
  }

  /// Returns the lightCode colors for the current theme.
  LightCodeColors _getThemeColors() {
    return _supportedCustomColor[_appTheme] ?? LightCodeColors();
  }

  /// Returns the current theme data.
  ThemeData _getThemeData() {
    var colorScheme =
        _supportedColorScheme[_appTheme] ?? ColorSchemes.lightCodeColorScheme;
    return ThemeData(
      visualDensity: VisualDensity.standard,
      colorScheme: colorScheme,
      textTheme: TextThemes.textTheme(colorScheme),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5.h),
          ),
          elevation: 0,
          visualDensity: const VisualDensity(
            vertical: -4,
            horizontal: -4,
          ),
          padding: EdgeInsets.zero,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          side: BorderSide(
            color: appTheme.whiteA700,
            width: 1.h,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22.h),
          ),
          visualDensity: const VisualDensity(
            vertical: -4,
            horizontal: -4,
          ),
          padding: EdgeInsets.zero,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
        side: BorderSide(
          width: 1,
        ),
        visualDensity: const VisualDensity(
          vertical: -4,
          horizontal: -4,
        ),
      ),
      dividerTheme: DividerThemeData(
        thickness: 1,
        space: 1,
        color: appTheme.gray30001,
      ),
    );
  }

  /// Returns the lightCode colors for the current theme.
  LightCodeColors themeColor() => _getThemeColors();

  /// Returns the current theme data.
  ThemeData themeData() => _getThemeData();
}

/// Class containing the supported text theme styles.
class TextThemes {
  static TextTheme textTheme(ColorScheme colorScheme) => TextTheme(
        bodyLarge: TextStyle(
          color: appTheme.gray800,
          fontSize: 16.fSize,
          fontFamily: 'Public Sans',
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          color: appTheme.black900,
          fontSize: 14.fSize,
          fontFamily: 'Public Sans',
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          color: appTheme.gray700,
          fontSize: 12.fSize,
          fontFamily: 'Public Sans',
          fontWeight: FontWeight.w400,
        ),
        displayMedium: TextStyle(
          color: appTheme.whiteA700,
          fontSize: 49.fSize,
          fontFamily: 'Public Sans',
          fontWeight: FontWeight.w400,
        ),
        headlineMedium: TextStyle(
          color: appTheme.black900,
          fontSize: 27.fSize,
          fontFamily: 'Public Sans',
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: TextStyle(
          color: colorScheme.onPrimary,
          fontSize: 24.fSize,
          fontFamily: 'Public Sans',
          fontWeight: FontWeight.w500,
        ),
        labelLarge: TextStyle(
          color: appTheme.gray800,
          fontSize: 13.fSize,
          fontFamily: 'Public Sans',
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          color: appTheme.whiteA700,
          fontSize: 10.fSize,
          fontFamily: 'Lato',
          fontWeight: FontWeight.w500,
        ),
        titleLarge: TextStyle(
          color: appTheme.black900,
          fontSize: 20.fSize,
          fontFamily: 'Public Sans',
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: colorScheme.onPrimary,
          fontSize: 16.fSize,
          fontFamily: 'Public Sans',
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: appTheme.gray700,
          fontSize: 14.fSize,
          fontFamily: 'Public Sans',
          fontWeight: FontWeight.w500,
        ),
      );
}

/// Class containing the supported color schemes.
class ColorSchemes {
  static final lightCodeColorScheme = ColorScheme.light(
    primary: Color(0XFF4675C0),
    primaryContainer: Color(0XFF1E1E1E),
    secondaryContainer: Color(0XFF757575),
    errorContainer: Color(0XFF575555),
    onError: Color(0XFF02A1FA),
    onErrorContainer: Color(0XFF10003D),
    onPrimary: Color(0XFF15131B),
    onPrimaryContainer: Color(0XFFB7B3AA),
  );
}

/// Class containing custom colors for a lightCode theme.
class LightCodeColors {
  // Amber
  Color get amber600 => Color(0XFFFFB700);
// Black
  Color get black900 => Color(0XFF000000);
// Blue
  Color get blue50 => Color(0XFFECF3FF);
  Color get blueA700 => Color(0XFF0065FF);
// BlueGray
  Color get blueGray100 => Color(0XFFD2D2D2);
  Color get blueGray10001 => Color(0XFFDBD6D6);
  Color get blueGray800 => Color(0XFF253D64);
  Color get blueGray800B2 => Color(0XB238425C);
  Color get blueGray800E5 => Color(0XE520365A);
// Cyan
  Color get cyan800 => Color(0XFF0079A0);
// DeepOrange
  Color get deepOrangeA200 => Color(0XFFFB7A34);
  Color get deepOrangeA400 => Color(0XFFFF5000);
// DeepPurple
  Color get deepPurple50 => Color(0XFFEDDBFF);
  Color get deepPurpleA700 => Color(0XFF7E02FA);
// Gray
  Color get gray100 => Color(0XFFF1F4F5);
  Color get gray10001 => Color(0XFFF2F2F2);
  Color get gray200 => Color(0XFFECECEC);
  Color get gray300 => Color(0XFFE5E5E5);
  Color get gray30001 => Color(0XFFE0E0E0);
  Color get gray30002 => Color(0XFFE3E4E8);
  Color get gray400 => Color(0XFFC4C4C4);
  Color get gray50 => Color(0XFFF6F8F9);
  Color get gray5001 => Color(0XFFFFFBFB);
  Color get gray5002 => Color(0XFFF7F9FA);
  Color get gray5003 => Color(0XFFFEF7FF);
  Color get gray600 => Color(0XFF797474);
  Color get gray700 => Color(0XFF686868);
  Color get gray70001 => Color(0XFF666666);
  Color get gray800 => Color(0XFF4B4B4B);
  Color get gray900 => Color(0XFF1D1B20);
// Green
  Color get green50 => Color(0XFFE6FFF0);
  Color get greenA400 => Color(0XFF00FF75);
  Color get greenA700 => Color(0XFF11A44C);
// LightBlue
  Color get lightBlue400 => Color(0XFF20AFFF);
  Color get lightBlue900 => Color(0XFF1166A4);
// Pink
  Color get pink50 => Color(0XFFFFE4EE);
  Color get pink5001 => Color(0XFFFFDDE9);
  Color get pinkA400 => Color(0XFFFA025B);
// Red
  Color get redA700 => Color(0XFFFF0000);
// White
  Color get whiteA700 => Color(0XFFFFFFFF);
}
