import 'package:flutter/material.dart';

class PharmacyListItemWidget extends StatelessWidget {
  final String id;
  final String pharmacyName;
  final String licenseNumber;
  final String phone;
  final String mobile;
  final double rating;
  final int totalUsers;

  const PharmacyListItemWidget({
    Key? key,
    required this.id,
    required this.pharmacyName,
    required this.licenseNumber,
    required this.phone,
    required this.mobile,
    required this.rating,
    required this.totalUsers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pharmacy Name as ID badge and Rating in same row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0XFF4675C0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    pharmacyName,
                    style: TextStyle(
                      color: Color(0XFF4675C0),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              SizedBox(width: 12),
              _buildRatingBadge(),
            ],
          ),

          SizedBox(height: 16),

          // License Number
          if (licenseNumber.isNotEmpty)
            Row(
              children: [
                Icon(
                  Icons.badge_outlined,
                  size: 16,
                  color: Colors.grey[600],
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "License: $licenseNumber",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

          if (licenseNumber.isNotEmpty) SizedBox(height: 12),

          // Phone Number
          if (phone.isNotEmpty)
            Row(
              children: [
                Icon(
                  Icons.phone_outlined,
                  size: 16,
                  color: Colors.grey[600],
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Phone: $phone",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

          if (phone.isNotEmpty) SizedBox(height: 12),

          // Mobile Number
          if (mobile.isNotEmpty)
            Row(
              children: [
                Icon(
                  Icons.phone_android_outlined,
                  size: 16,
                  color: Colors.grey[600],
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Mobile: $mobile",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRatingBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.amber.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            size: 16,
            color: Colors.amber[700],
          ),
          SizedBox(width: 6),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.amber[700],
            ),
          ),
          if (totalUsers > 0) ...[
            SizedBox(width: 4),
            Text(
              "($totalUsers)",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.amber[700],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
