import 'dart:async';
import 'package:flutter/material.dart';

/// Shared helpers for delivery request list screens.
class DeliveryRequestHelpers {
  static String resolvePharmacyName(Map<String, dynamic> order) {
    final org = order['org_organization_name']?.toString().trim() ?? '';
    if (org.isNotEmpty) return org;

    final first = order['pha_first_name']?.toString().trim() ?? '';
    final last = order['pha_last_name']?.toString().trim() ?? '';
    final fullName = '$first $last'.trim();
    if (fullName.isNotEmpty) return fullName;

    return order['pharmacy_name']?.toString().trim() ??
        order['organization_name']?.toString().trim() ??
        order['usr_username']?.toString().trim() ??
        'Unknown Pharmacy';
  }

  static String resolvePharmacyPhone(Map<String, dynamic> order) {
    return order['pharmacy_phone']?.toString().trim() ??
        order['pha_alt_phone_number']?.toString().trim() ??
        order['usr_mobile_number']?.toString().trim() ??
        '';
  }

  static DateTime? resolveRequestTime(Map<String, dynamic> order) {
    for (final key in [
      'del_created_dt',
      'ord_created_dt',
      'del_pickup_time',
    ]) {
      final raw = order[key]?.toString().trim();
      if (raw != null && raw.isNotEmpty) {
        final parsed = DateTime.tryParse(raw);
        if (parsed != null) return parsed.toLocal();
      }
    }
    return null;
  }
}

class DeliveryRequestItemWidget extends StatefulWidget {
  final String id;
  final String pharmacyName;
  final String phoneNumber;
  final DateTime? requestTime;
  final int oid;

  const DeliveryRequestItemWidget({
    super.key,
    required this.id,
    required this.pharmacyName,
    required this.phoneNumber,
    required this.requestTime,
    required this.oid,
  });

  @override
  State<DeliveryRequestItemWidget> createState() =>
      _DeliveryRequestItemWidgetState();
}

class _DeliveryRequestItemWidgetState extends State<DeliveryRequestItemWidget> {
  Timer? _timer;
  String _elapsedLabel = '--';

  @override
  void initState() {
    super.initState();
    _updateElapsed();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateElapsed());
  }

  @override
  void didUpdateWidget(covariant DeliveryRequestItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.requestTime != widget.requestTime) {
      _updateElapsed();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateElapsed() {
    final requestTime = widget.requestTime;
    if (requestTime == null) {
      if (mounted) setState(() => _elapsedLabel = '--');
      return;
    }

    final elapsed = DateTime.now().difference(requestTime);
    if (elapsed.isNegative) {
      if (mounted) setState(() => _elapsedLabel = '0 Sec');
      return;
    }

    if (mounted) {
      setState(() => _elapsedLabel = _formatDuration(elapsed));
    }
  }

  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (duration.inHours >= 24) {
      return '$days Days | $hours Hours | $minutes Mins | $seconds Sec';
    }

    final totalHours = duration.inHours;
    if (totalHours > 0) {
      return '$totalHours Hours | $minutes Mins | $seconds Sec';
    }
    if (minutes > 0) {
      return '$minutes Mins | $seconds Sec';
    }
    return '$seconds Sec';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/delivery_details',
          arguments: {
            'orderId': widget.oid,
            'requestId': widget.id,
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0XFF4675C0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#${widget.id}',
                    style: const TextStyle(
                      color: Color(0XFF4675C0),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _buildTimerBadge(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.local_pharmacy,
                  size: 22,
                  color: const Color(0XFF4675C0),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.pharmacyName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (widget.phoneNumber.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.phone,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.phoneNumber,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimerBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.timer_outlined,
            size: 16,
            color: Colors.orange,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _elapsedLabel,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.orange,
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
