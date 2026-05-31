part of 'fix_login_form_widgets.dart';

class FixFlowInfo extends StatelessWidget {
  const FixFlowInfo({
    super.key,
    required this.modeLabel,
    required this.isRegister,
  });

  final String modeLabel;
  final bool isRegister;

  @override
  Widget build(BuildContext context) {
    final action = isRegister ? 'kayıt' : 'giriş';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF1FBF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD7F2E0)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user_outlined,
            color: Color(0xFF1DB954),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$modeLabel $action ekranındasınız',
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF25643A),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
