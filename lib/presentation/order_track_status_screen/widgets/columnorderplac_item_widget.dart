import 'package:flutter/material.dart';
import 'package:timelines_plus/timelines_plus.dart';
import '../../../core/app_export.dart';
import 'columntime_item_widget.dart';
import 'columnview_item_widget.dart';

class ColumnorderplacItemWidget extends StatelessWidget {
  final String status;

  const ColumnorderplacItemWidget({Key? key, required this.status})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 17, bottom: 8),
      child: Text(
        status,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}
