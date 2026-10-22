import 'package:flutter/material.dart';
import '../core/config/app_config.dart';
import '../core/config/app_version_info.dart';

/// Shows the QuikDawa build label, e.g. `v2026.D.2.06` or `v2026.P.2.06`.
class AppVersionLabel extends StatelessWidget {
  const AppVersionLabel({
    super.key,
    this.style,
    this.textAlign = TextAlign.center,
    this.inDrawerHeader = false,
  });

  final TextStyle? style;
  final TextAlign textAlign;

  /// When `true`, renders a compact label for the drawer header below "Welcome Back!".
  final bool inDrawerHeader;

  @override
  Widget build(BuildContext context) {
    final label = AppVersionInfo.displayLabel;

    if (inDrawerHeader) {
      return _buildDrawerHeaderLabel(label);
    }

    final defaultStyle = TextStyle(
      color: Colors.grey[500],
      fontSize: 11,
      fontWeight: FontWeight.w400,
    );

    return Text(
      label,
      textAlign: textAlign,
      style: style ?? defaultStyle,
    );
  }

  Widget _buildDrawerHeaderLabel(String label) {
    final textStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: AppConfig.isDevelopment ? Colors.black87 : Colors.white.withOpacity(0.75),
    );

    final text = Text(
      label,
      textAlign: TextAlign.start,
      style: style ?? textStyle,
    );

    if (AppConfig.isDevelopment) {
      return Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.yellow[600],
          borderRadius: BorderRadius.circular(4),
        ),
        child: text,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: text,
    );
  }
}
