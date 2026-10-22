import 'package:flutter/material.dart';
import 'package:timelines_plus/timelines_plus.dart';
import '../../../../core/app_export.dart';
import 'columntime_item_widget.dart';

class ColumnviewItemWidget extends StatelessWidget {
  final Color color;

  const ColumnviewItemWidget({Key? key, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      height: 14,
      width: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
