part of 'fix_login_form_widgets.dart';

class FixLoginPanel extends StatelessWidget {
  const FixLoginPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.bullets = const <String>[],
    this.notice,
    this.noticeIsError = true,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final List<String> bullets;
  final String? notice;
  final bool noticeIsError;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1ECEB)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF17384A).withValues(alpha: 0.07),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: Color(0xFF17384A),
              height: 1.08,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (bullets.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: bullets
                  .map(
                    (item) => _FixValueChip(label: item),
                  )
                  .toList(growable: false),
            ),
          ],
          if (notice?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 12),
            _FixInlineNotice(
              message: notice!.trim(),
              isError: noticeIsError,
            ),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class FixModeHint extends StatelessWidget {
  const FixModeHint({
    super.key,
    required this.isCorporate,
  });

  final bool isCorporate;

  @override
  Widget build(BuildContext context) {
    final text = isCorporate
        ? 'Kurumsal: işletmeni ve randevularını yönet'
        : 'Bireysel: randevu al, işletmeleri keşfet';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: Container(
        key: ValueKey<bool>(isCorporate),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FBFA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE1ECEB)),
        ),
        child: Row(
          children: [
            Icon(
              isCorporate
                  ? Icons.storefront_outlined
                  : Icons.person_outline_rounded,
              color: const Color(0xFF1DB954),
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FixInlineNotice extends StatelessWidget {
  const _FixInlineNotice({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? const Color(0xFFDC2626) : const Color(0xFF15803D);
    final background = isError
        ? const Color(0xFFFFF1F2)
        : const Color(0xFFEFFAF4);
    final border = isError ? const Color(0xFFFECACA) : const Color(0xFFD7F2E0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline,
            color: color,
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 12,
                height: 1.25,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FixValueChip extends StatelessWidget {
  const _FixValueChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFAF4),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD7F2E0)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF25643A),
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
