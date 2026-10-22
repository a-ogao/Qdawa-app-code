import 'package:flutter/material.dart';

class OrderListOneItemWidget extends StatelessWidget {
  final String id; // Actual order ID for backend/navigation
  final String displayId; // Display ID for users (qre_request_id)
  final String customerName;
  final String pharmacyName;
  final String pharmacyPhone;
  final String date;
  final String amount;
  final String status;
  final String? couponCode;
  final String? couponDiscount;

  const OrderListOneItemWidget({
    Key? key,
    required this.id,
    required this.displayId,
    required this.customerName,
    required this.pharmacyName,
    required this.pharmacyPhone,
    required this.date,
    required this.amount,
    required this.status,
    this.couponCode,
    this.couponDiscount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/order_track_status_screen',
          arguments: {'orderId': id},
        );
      },
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID and Status badges in same row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "ID: #$displayId",
                  style: TextStyle(
                    color: Color(0XFF4675C0),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
                  "KSH $amount",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[600],
                  ),
                ),
                if (couponCode != null &&
                    couponCode!.isNotEmpty &&
                    couponDiscount != null &&
                    double.tryParse(couponDiscount!) != null &&
                    double.parse(couponDiscount!) > 0) ...[
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      '$couponCode (-KES $couponDiscount)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            SizedBox(height: 12),

            // Pharmacy info
            if (pharmacyName.isNotEmpty || pharmacyPhone.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (pharmacyName.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.local_pharmacy_outlined,
                          size: 16,
                          color: Colors.grey[700],
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            pharmacyName,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  if (pharmacyName.isNotEmpty && pharmacyPhone.isNotEmpty)
                    SizedBox(height: 6),
                  if (pharmacyPhone.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 16,
                          color: Colors.grey[700],
                        ),
                        SizedBox(width: 8),
                        Text(
                          pharmacyPhone,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: 8),
                ],
              ),

            // Date
            if (date.isNotEmpty)
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 8),
                  Text(
                    date,
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
        statusText = "Pending";
        statusIcon = Icons.schedule;
        break;
      case "delivered":
        statusColor = Colors.blue;
        statusText = "Delivered";
        statusIcon = Icons.check_circle;
        break;
      case "dispatched":
        statusColor = Colors.green;
        statusText = "Dispatched";
        statusIcon = Icons.local_shipping;
        break;
      case "ready":
        statusColor = Colors.orange;
        statusText = "Ready";
        statusIcon = Icons.check_circle_outline;
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
