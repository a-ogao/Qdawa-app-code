import 'package:flutter/material.dart';

/// Shown when API returns `pii_deidentified: true` (tagged identity only).
class PiiDeidentifiedBadge extends StatelessWidget {
  const PiiDeidentifiedBadge({Key? key, this.compact = false}) : super(key: key);

  final bool compact;

  static bool isDeidentified(dynamic value) {
    if (value == true || value == 1 || value == '1') return true;
    if (value == false || value == 0 || value == '0') return false;
    return value?.toString().toLowerCase() == 'true';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.visibility_off_outlined,
            size: compact ? 12 : 14,
            color: Colors.orange.shade800,
          ),
          SizedBox(width: 4),
          Text(
            compact ? 'De-identified' : 'De-identified contact',
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade900,
            ),
          ),
        ],
      ),
    );
  }
}
