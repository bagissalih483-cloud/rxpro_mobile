import 'package:flutter/material.dart';
import 'package:rxpro_mobile/features/businesses/data/business_customer_repository.dart';

class BusinessCustomerMetricPill extends StatelessWidget {
  const BusinessCustomerMetricPill({
    super.key,
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF475569)),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class BusinessCustomerSegmentBadge extends StatelessWidget {
  const BusinessCustomerSegmentBadge({super.key, required this.segmentId});

  final String segmentId;

  @override
  Widget build(BuildContext context) {
    final color = businessCustomerSegmentColor(segmentId);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        BusinessCustomerSegments.labelOf(segmentId),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }
}

Color businessCustomerSegmentColor(String segmentId) {
  switch (segmentId) {
    case 'new_customer':
      return const Color(0xFF2563EB);
    case 'active':
      return const Color(0xFF0F766E);
    case 'loyal':
      return const Color(0xFF7C3AED);
    case 'inactive':
      return const Color(0xFF64748B);
    case 'needs_follow_up':
      return const Color(0xFFDC2626);
    default:
      return const Color(0xFFC2410C);
  }
}
