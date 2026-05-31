part of 'accounting_receivables_page.dart';

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.filter, required this.onChanged});

  final String filter;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FilterChipButton(
          selected: filter == 'all',
          label: 'T\u00fcm\u00fc',
          onTap: () => onChanged('all'),
        ),
        _FilterChipButton(
          selected: filter == 'unpaid',
          label: 'Bekleyen',
          onTap: () => onChanged('unpaid'),
        ),
        _FilterChipButton(
          selected: filter == 'partial',
          label: 'K\u0131smi',
          onTap: () => onChanged('partial'),
        ),
        _FilterChipButton(
          selected: filter == 'installment',
          label: 'Taksitler',
          onTap: () => onChanged('installment'),
        ),
        _FilterChipButton(
          selected: filter == 'overdue',
          label: 'Geciken',
          onTap: () => onChanged('overdue'),
        ),
      ],
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w800,
        color: selected ? Colors.white : const Color(0xFF334155),
      ),
      selectedColor: const Color(0xFF10B981),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
      ),
      onSelected: (_) => onTap(),
    );
  }
}
