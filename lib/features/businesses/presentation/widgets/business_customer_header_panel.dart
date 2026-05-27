import 'package:flutter/material.dart';

class BusinessCustomerHeaderPanel extends StatelessWidget {
  const BusinessCustomerHeaderPanel({
    super.key,
    required this.businessName,
    required this.total,
    required this.visible,
    required this.onAddCustomer,
    required this.onBulkMessage,
  });

  final String businessName;
  final int total;
  final int visible;
  final VoidCallback onAddCustomer;
  final VoidCallback onBulkMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFEFF6FF),
                child: Icon(Icons.groups_2_outlined, color: Color(0xFF2563EB)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      businessName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$total müşteri kaydı, bu görünümde $visible hedef',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onAddCustomer,
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text('Müşteri ekle'),
                  style: FilledButton.styleFrom(
                    foregroundColor: const Color(0xFF0F766E),
                    backgroundColor: const Color(0xFFE9FFF4),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onBulkMessage,
                  icon: const Icon(Icons.campaign_outlined),
                  label: const Text('Toplu mesaj'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
