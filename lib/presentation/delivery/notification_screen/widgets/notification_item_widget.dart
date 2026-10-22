import 'package:flutter/material.dart';

class QuotationRequestItemWidget extends StatelessWidget {
  final String Requestid;
  final String requeststatus;
  final String requestdate;
  final String qstatus;

  const QuotationRequestItemWidget({
    Key? key,
    required this.Requestid,
    required this.requeststatus,
    required this.requestdate,
    required this.qstatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme for styling

    return GestureDetector(
      onTap: () {
        if (qstatus.toLowerCase() != "pending") {
          /* Navigator.pushNamed(
            context,
            '/quotation_list_screen',
            arguments: {'Requestid': Requestid},
          ); */
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Please Wait for Quotation!"),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Container(
          width: double.infinity, // Full width
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Column(
            // Column instead of Row to avoid text cutoff
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "#$Requestid",
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4), // Small spacing
              Text(
                requestdate,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                requeststatus,
                style: theme.textTheme.bodyMedium, // Ensure readable text
                softWrap: true, // Enables wrapping
              ),
            ],
          ),
        ),
      ),
    );
  }
}
