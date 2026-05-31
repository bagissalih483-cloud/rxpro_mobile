part of 'account_entry_menu.dart';

String _displayNameOf(User? user) {
  final name = user?.displayName?.trim() ?? '';
  if (name.isNotEmpty) return name;

  final email = user?.email?.trim() ?? '';
  if (email.isNotEmpty) return email;

  final phone = user?.phoneNumber?.trim() ?? '';
  if (phone.isNotEmpty) return phone;

  return 'fi Hesabı';
}

String _profilePhotoOf(AccountEntryContext ctx) {
  final candidates = <Object?>[
    ctx.user?.photoURL,
    ctx.userData['photoUrl'],
    ctx.userData['imageUrl'],
    ctx.userData['avatarUrl'],
    ctx.business?.data['logoUrl'],
    ctx.business?.data['photoUrl'],
    ctx.business?.data['imageUrl'],
  ];

  for (final candidate in candidates) {
    final value = candidate?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }

  return '';
}

class _LiveFlowActionTile extends StatelessWidget {
  const _LiveFlowActionTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.026),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9FFF4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.play_circle_outline_rounded,
                  color: Color(0xFF0F766E),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Canlı Akış',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Günlük operasyon, ekip durumu ve aktif işler.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
            ],
          ),
        ),
      ),
    );
  }
}
