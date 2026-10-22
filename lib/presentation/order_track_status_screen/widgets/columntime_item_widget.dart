import 'package:flutter/material.dart';
import 'package:timelines_plus/timelines_plus.dart';
import '../../../core/app_export.dart';

class ColumntimeItemWidget extends StatelessWidget {
  final String time;

  const ColumntimeItemWidget({Key? key, required this.time}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, right: 12, bottom: 8),
      child: Text(
        time,
        style: const TextStyle(fontSize: 14, color: Colors.black),
      ),
    );
  }
}
