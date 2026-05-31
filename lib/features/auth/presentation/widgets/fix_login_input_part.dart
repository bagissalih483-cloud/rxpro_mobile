part of 'fix_login_form_widgets.dart';

class FixInput extends StatelessWidget {
  const FixInput({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboardType,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      textCapitalization: textCapitalization,
      textInputAction: TextInputAction.next,
      style: const TextStyle(
        color: Color(0xFF17384A),
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
      ),
      decoration: fixInputDecoration(
        label: label,
        icon: icon,
      ).copyWith(hintText: hint),
    );
  }
}

InputDecoration fixInputDecoration({
  required String label,
  required IconData icon,
}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFFDEE9E8)),
  );

  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, size: 20, color: const Color(0xFF60727A)),
    filled: true,
    fillColor: const Color(0xFFFAFDFD),
    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: const BorderSide(color: Color(0xFF1DB954), width: 1.7),
    ),
  );
}
