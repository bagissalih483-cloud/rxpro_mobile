part of 'business_appointment_management_widgets.dart';

Future<void> showBusinessCustomerQuickProfile({
  required BuildContext context,
  required String businessId,
  required String businessName,
  required Map<String, dynamic> data,
  required String customerName,
}) async {
  final email = _field(data, ['customerEmail', 'email', 'clientEmail']);
  final phone = _field(data, ['customerPhone', 'phone', 'clientPhone']);
  final uid = _field(data, [
    'customerUid',
    'customerId',
    'userId',
    'uid',
    'clientUid',
  ]);

  await showRxAdaptiveModal<void>(
    context: context,
    desktopMaxWidth: 480,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: const Color(0xFFEFF6FF),
                child: Text(
                  _initialsOf(customerName),
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                customerName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              if (email.isNotEmpty && email != '-')
                BusinessCustomerInfoLine(
                  icon: Icons.mail_outline_rounded,
                  text: email,
                ),
              if (phone.isNotEmpty && phone != '-')
                BusinessCustomerInfoLine(
                  icon: Icons.phone_outlined,
                  text: phone,
                ),
              if (uid.isNotEmpty && uid != '-')
                BusinessCustomerInfoLine(
                  icon: Icons.badge_outlined,
                  text: 'Kullanıcı ID: $uid',
                ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();

                    if (uid.isEmpty || uid == '-') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Bireysel kullanıcı ID bilgisi bulunamadı.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    Navigator.of(context).pushNamed(
                      AppRoutes.businessCustomerDirectMessage,
                      arguments: BusinessCustomerDirectMessageRouteArgs(
                        businessId: businessId,
                        businessName: businessName,
                        customerUid: uid,
                        customerName: customerName,
                        customerEmail: email,
                        customerPhone: phone,
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Mesaj Gönder'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

String _field(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }

  return '';
}

String _initialsOf(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return 'M';
  final parts = trimmed
      .split(RegExp(r'\s+'))
      .where((part) => part.trim().isNotEmpty)
      .toList();

  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }

  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}

class BusinessCustomerInfoLine extends StatelessWidget {
  const BusinessCustomerInfoLine({
    super.key,
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
