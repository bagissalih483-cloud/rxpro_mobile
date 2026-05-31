part of 'fix_login_form_widgets.dart';

class FixRememberPasswordTile extends StatelessWidget {
  const FixRememberPasswordTile({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: Container(
          padding: const EdgeInsets.fromLTRB(0, 0, 9, 0),
          decoration: BoxDecoration(
            color: value ? const Color(0xFFE9FFF4) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: value,
                onChanged: onChanged,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeColor: const Color(0xFF1DB954),
              ),
              const SizedBox(width: 2),
              const Text(
                'Beni hatırla',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF495057),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
