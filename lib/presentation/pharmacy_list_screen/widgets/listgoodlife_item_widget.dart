import 'package:flutter/material.dart';
import '../../../core/app_export.dart';

class ListgoodlifeItemWidget extends StatelessWidget {
  const ListgoodlifeItemWidget({Key? key})
      : super(
          key: key,
        );

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: "Goodlife Pharmacy\n",
            style: theme.textTheme.titleMedium,
          ),
          TextSpan(
            text: "Kenyatta Avenue\n+254 701 747474",
            style: theme.textTheme.titleSmall,
          )
        ],
      ),
      textAlign: TextAlign.left,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}
