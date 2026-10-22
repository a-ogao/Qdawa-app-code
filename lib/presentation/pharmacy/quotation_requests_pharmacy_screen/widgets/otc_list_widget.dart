import 'package:flutter/material.dart';
import '../../../../widgets/pii_deidentified_badge.dart';

class OTClistWidget extends StatelessWidget {
  final String name;
  final String location;
  final String phone;
  final String price;
  final String status;
  final int id;
  final String requestCode;
  final bool isDeidentified;
  const OTClistWidget({
    required this.name,
    required this.location,
    required this.phone,
    required this.price,
    required this.status,
    required this.id,
    required this.requestCode,
    this.isDeidentified = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (status == "pending") {
          Navigator.pushNamed(
            context,
            '/submit_otc_screen',
            arguments: {
              'id': id,
            },
          );
        } else {
          Navigator.pushNamed(
            context,
            '/view_quotation_screen',
            arguments: {
              'id': id,
            },
          );
        }
      },
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Request ID and Status badges in same row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0XFF4675C0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "#$requestCode",
                    style: TextStyle(
                      color: Color(0XFF4675C0),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _buildStatusBadge(),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Amount
            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  size: 20,
                  color: Colors.green[600],
                ),
                SizedBox(width: 8),
                Text(
                  "KSH $price",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            // Patient name
            if (name.isNotEmpty)
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isDeidentified) const PiiDeidentifiedBadge(compact: true),
                ],
              ),
            
            if (name.isNotEmpty) SizedBox(height: 8),
            
            // Location
            if (location.isNotEmpty)
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      location,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            
            if (location.isNotEmpty) SizedBox(height: 8),
            
            // Phone
            if (phone.isNotEmpty)
              Row(
                children: [
                  Icon(
                    Icons.phone_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 8),
                  Text(
                    phone,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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

    switch (status.toLowerCase()) {
      case "pending":
        statusColor = Colors.orange;
        statusText = "Submit Quotation";
        statusIcon = Icons.schedule;
        break;
      case "received":
        statusColor = Colors.blue;
        statusText = "Quotation Sent";
        statusIcon = Icons.send;
        break;
      case "accepted":
        statusColor = Colors.green;
        statusText = "Accepted";
        statusIcon = Icons.check_circle;
        break;
      case "rejected":
        statusColor = Colors.red;
        statusText = "Rejected";
        statusIcon = Icons.cancel;
        break;
      case "cancelled":
        statusColor = Colors.red;
        statusText = "Cancelled";
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusText = status;
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
