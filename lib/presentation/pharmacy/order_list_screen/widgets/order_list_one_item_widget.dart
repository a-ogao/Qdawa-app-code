import 'package:flutter/material.dart';
import '../../../../widgets/pii_deidentified_badge.dart';

class OrderListOneItemWidget extends StatelessWidget {
  final String id;
  final String customerName;
  final String username;
  final String amount;
  final String status;
  final String address;
  final String order_type;
  final String quotationReqId;
  final bool isDeidentified;
  final String? couponCode;
  final String? couponDiscount;

  const OrderListOneItemWidget({
    Key? key,
    required this.id,
    required this.customerName,
    required this.username,
    required this.amount,
    required this.status,
    required this.address,
    required this.order_type,
    required this.quotationReqId,
    this.isDeidentified = false,
    this.couponCode,
    this.couponDiscount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/order_view',
          arguments: {
            'orderId': id,
          },
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
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0XFF4675C0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "#$quotationReqId",
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
                  Flexible(
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            SizedBox(height: 12),

            // Customer info
            if (username.isNotEmpty)
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
                      username,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isDeidentified) const PiiDeidentifiedBadge(compact: true),
                ],
              ),

            if (username.isNotEmpty) SizedBox(height: 8),

            // Address
            if (address.isNotEmpty)
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
                      address,
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
        statusColor = Color(0xFFFF9800); // Orange for Preparing
        statusText = "Preparing";
        statusIcon = Icons.schedule;
        break;
      case "ready":
        statusColor = Color(0xFF2196F3); // Blue for Ready
        statusText = "Ready";
        statusIcon = Icons.check_circle_outline;
        break;
      case "dispatched":
        statusColor = Color(0xFF4CAF50); // Green for Dispatched
        statusText = "Dispatched";
        statusIcon = Icons.local_shipping;
        break;
      case "delivered":
        statusColor = Color(0xFF00BCD4); // Cyan/Teal for Delivered
        statusText = "Delivered";
        statusIcon = Icons.check_circle;
        break;
      case "pickedup":
        statusColor = Color(0xFF9C27B0); // Purple for Picked Up
        statusText = "Picked Up";
        statusIcon = Icons.done_all;
        break;
      case "cancelled":
        statusColor = Color(0xFFF44336); // Red for Cancelled
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
