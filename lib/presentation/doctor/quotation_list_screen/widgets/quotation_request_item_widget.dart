import 'package:flutter/material.dart';

class QuotationRequestItemWidget extends StatelessWidget {
  final String Requestid;
  final String requeststatus;
  final String requestdate;
  final String qstatus;
  final String patientName;

  const QuotationRequestItemWidget({
    Key? key,
    required this.Requestid,
    required this.requeststatus,
    required this.requestdate,
    required this.qstatus,
    this.patientName = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (qstatus.toLowerCase() != "pending") {
          Navigator.pushNamed(
            context,
            '/quotation_dlist_screen',
            arguments: {'Requestid': Requestid},
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Please Wait for Quotation!"),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side - Quotation info
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quotation ID with badge
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

                    // Patient Name (displayed after ID if available)
                    if (patientName.isNotEmpty) ...[
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 6),
                          Text(
                            patientName,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],

                    SizedBox(height: 12),

                    // Date info
                    if (requestdate.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              requestdate,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
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
                    // Status badge
                    _buildStatusBadge(),
                  ],
                ),
              ),
            ],
          ),
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
        statusText = "Received";
        statusIcon = Icons.download;
        break;
      case "cancelled":
        statusColor = Colors.red;
        statusText = "Cancelled";
        statusIcon = Icons.cancel;
        break;
      case "otc_rejected":
        statusColor = Colors.red;
        statusText = "OTC Rejected";
        statusIcon = Icons.block;
        break;
      case "accepted":
        statusColor = Colors.green;
        statusText = "Accepted";
        statusIcon = Icons.check_circle;
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
}
