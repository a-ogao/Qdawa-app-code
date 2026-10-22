import 'package:flutter/material.dart';

class DeliveredOrdersListItem extends StatelessWidget {
  final String id;
  final String date;
  final String amount;
  final int oid;
  final String pharmacyName;
  const DeliveredOrdersListItem({
    Key? key,
    required this.id,
    required this.date,
    required this.amount,
    required this.oid,
    required this.pharmacyName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to QuotationScreen and pass the Requestid
        Navigator.pushNamed(
          context,
          '/delivery_details', // Define the route name in your app routes
          arguments: {
            'orderId': oid,
            'requestId': id, // Pass Requestid as argument
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
                    "#$id",
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
              ],
            ),

            SizedBox(height: 12),

            // Pharmacy Name
            if (pharmacyName.isNotEmpty)
              Row(
                children: [
                  Icon(
                    Icons.store_mall_directory,
                    size: 16,
                    color: Colors.grey[600],
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
                    ),
                  ),
                ],
              ),

            if (pharmacyName.isNotEmpty) SizedBox(height: 8),

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
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: Colors.blue,
          ),
          SizedBox(width: 6),
          Text(
            "Delivered",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
