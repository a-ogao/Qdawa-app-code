import 'package:flutter/material.dart';

class CustomElevatedButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double height;
  final EdgeInsets margin;
  final ButtonStyle buttonStyle;
  final TextStyle buttonTextStyle;

  const CustomElevatedButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.height = 50.0,
    this.margin = EdgeInsets.zero,
    required this.buttonStyle,
    required this.buttonTextStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      height: height,
      child: ElevatedButton(
        style: buttonStyle,
        onPressed: onPressed,
        child: Text(text, style: buttonTextStyle),
      ),
    );
  }
}
