part of '../../business_profile_page.dart';

class _RxBookingDateTile extends StatelessWidget {
  const _RxBookingDateTile({
    required this.weekday,
    required this.day,
    required this.month,
    required this.selected,
    required this.onTap,
  });

  final String weekday;
  final String day;
  final String month;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 58,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF7C3AED) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? const Color(0xFF7C3AED)
                  : const Color(0xFFE5E7EB),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                weekday,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white70 : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                day,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 16,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: selected ? Colors.white : const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                month,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 10,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white70 : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RxBookingTimeTile extends StatelessWidget {
  const _RxBookingTimeTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 40,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(76, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: selected ? const Color(0xFFEDE9FE) : Colors.white,
          foregroundColor: selected
              ? const Color(0xFF6D28D9)
              : const Color(0xFF111827),
          side: BorderSide(
            color: selected ? const Color(0xFF7C3AED) : const Color(0xFFE5E7EB),
            width: selected ? 1.4 : 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
