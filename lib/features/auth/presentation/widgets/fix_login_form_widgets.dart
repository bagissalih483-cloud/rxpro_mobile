import 'package:flutter/material.dart';

class FixSegmentedOption<T> {
  const FixSegmentedOption({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}

class FixSegmentedTabs<T> extends StatelessWidget {
  const FixSegmentedTabs({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.compact = false,
  });

  final T value;
  final List<FixSegmentedOption<T>> options;
  final ValueChanged<T>? onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 44 : 50,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: compact ? const Color(0xFFEFF4F3) : Colors.white,
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        border: compact ? null : Border.all(color: const Color(0xFFE1ECEB)),
      ),
      child: Row(
        children: options
            .map(
              (option) => Expanded(
                child: _FixSegmentButton<T>(
                  option: option,
                  selected: option.value == value,
                  compact: compact,
                  onTap: onChanged == null
                      ? null
                      : () => onChanged!(option.value),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

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
          padding: const EdgeInsets.fromLTRB(2, 2, 10, 2),
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
                'Şifreyi hatırla',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF495057),
                ),
              ),
              const SizedBox(width: 6),
              const Tooltip(
                message:
                    'E-posta otomatik hatırlanır. Şifre güvenli depolamada bireysel ve kurumsal olarak ayrı tutulur.',
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 15,
                  color: Color(0xFF6C757D),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FixLoginPanel extends StatelessWidget {
  const FixLoginPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE1ECEB)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF17384A).withValues(alpha: 0.05),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: Color(0xFF17384A),
              height: 1.08,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

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
    borderRadius: BorderRadius.circular(16),
    borderSide: const BorderSide(color: Color(0xFFDEE9E8)),
  );

  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: const Color(0xFFFAFDFD),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: const BorderSide(color: Color(0xFF1DB954), width: 1.7),
    ),
  );
}

class _FixSegmentButton<T> extends StatelessWidget {
  const _FixSegmentButton({
    required this.option,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final FixSegmentedOption<T> option;
  final bool selected;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        elevation: 0,
        backgroundColor: selected
            ? const Color(0xFF1DB954)
            : Colors.transparent,
        foregroundColor: selected ? Colors.white : const Color(0xFF60727A),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(compact ? 12 : 14),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (option.icon != null) ...[
            Icon(option.icon, size: compact ? 15 : 16),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              option.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 13 : 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
