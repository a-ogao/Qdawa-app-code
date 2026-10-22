import 'package:flutter/material.dart';

class QuotationRequestItemWidget extends StatelessWidget {
  final String Requestid;
  final String requeststatus;
  final String requestdate;
  final String qstatus;
  final String quoteamount;

  const QuotationRequestItemWidget({
    Key? key,
    required this.Requestid,
    required this.requeststatus,
    required this.requestdate,
    required this.qstatus,
    required this.quoteamount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (qstatus.toLowerCase() != "pending") {
          Navigator.pushNamed(
            context,
            '/quotation_list_screen',
            arguments: {'Requestid': Requestid},
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Please Wait for Quotation!"),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      child: Container(
        padding: EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side - Request info
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Request ID with badge
                  Row(
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0XFF4675C0).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "#$Requestid",
                          style: TextStyle(
                            color: Color(0XFF4675C0),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Amount
                  if (quoteamount.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.attach_money,
                          size: 20,
                          color: Colors.green[600],
                        ),
                        SizedBox(width: 8),
                        Text(
                          quoteamount,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),

                  if (quoteamount.isNotEmpty) SizedBox(height: 12),

                  // Date
                  if (requestdate.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 8),
                        Text(
                          _formatDate(requestdate),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            SizedBox(width: 16),

            // Right side - Status
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildStatusBadge(),

                  SizedBox(height: 12),

                  // Action hint for pending
                  if (qstatus.toLowerCase() == "pending")
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.purple[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.purple[300]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: Colors.purple[400],
                          ),
                          SizedBox(width: 6),
                          Text(
                            "Waiting",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.purple[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (qstatus.toLowerCase()) {
      case "pending":
        statusColor = Colors.orange;
        statusText = "Pending";
        statusIcon = Icons.schedule;
        break;
      case "rejected":
        statusColor = Colors.red;
        statusText = "Rejected";
        statusIcon = Icons.cancel;
        break;
      case "received":
        statusColor = Colors.blue;
        statusText = "Pay";
        statusIcon = Icons.payment;
        break;
      case "cancelled":
        statusColor = Colors.red;
        statusText = "Cancelled";
        statusIcon = Icons.cancel;
        break;
      case "accepted":
        statusColor = Colors.green;
        statusText = "Received";
        statusIcon = Icons.check_circle;
        break;
      case "otc_rejected":
        statusColor = Colors.red;
        statusText = "OTC Rejected";
        statusIcon = Icons.block;
        break;
      default:
        statusColor = Colors.grey;
        statusText = "Unknown";
        statusIcon = Icons.help;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 16,
            color: statusColor,
          ),
          SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      // Try to parse the date string and format it
      if (dateString.contains('T')) {
        // Handle ISO format
        DateTime date = DateTime.parse(dateString);
        return "${date.day}/${date.month}/${date.year}";
      } else {
        // Handle other formats
        return dateString;
      }
    } catch (e) {
      // Return original string if parsing fails
      return dateString;
    }
  }
}
