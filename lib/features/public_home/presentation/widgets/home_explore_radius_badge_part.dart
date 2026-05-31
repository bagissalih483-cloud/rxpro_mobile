part of 'home_explore_filter_widgets.dart';

class _RadiusBadge extends StatelessWidget {
  const _RadiusBadge({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF5FAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1ECEB)),
      ),
      child: Text(
        '${value.round()} km',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Color(0xFF216A6D),
        ),
      ),
    );
  }
}
