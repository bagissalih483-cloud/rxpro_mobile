part of 'account_entry_cards.dart';

class AccountMainAccordionCard extends StatelessWidget {
  const AccountMainAccordionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.expanded,
    required this.onTap,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool expanded;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: expanded ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: expanded ? 0.055 : 0.028),
            blurRadius: expanded ? 18 : 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 14, 13, 14),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: expanded
                            ? const Color(0xFFEFF6FF)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: expanded
                              ? const Color(0xFFBFDBFE)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: expanded
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                              fontSize: 12,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 180),
              crossFadeState: expanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: child,
              ),
              secondChild: const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

class AccountNestedAccordionCard extends StatelessWidget {
  const AccountNestedAccordionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: false,
      tilePadding: const EdgeInsets.symmetric(horizontal: 4),
      childrenPadding: const EdgeInsets.only(bottom: 8),
      leading: Icon(icon, color: const Color(0xFF0F766E)),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF64748B),
          fontSize: 12,
        ),
      ),
      children: children,
    );
  }
}
