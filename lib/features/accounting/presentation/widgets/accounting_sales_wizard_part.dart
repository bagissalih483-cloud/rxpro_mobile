part of 'accounting_sales_widgets.dart';

class AccountingWizardStepCard extends StatelessWidget {
  const AccountingWizardStepCard({
    super.key,
    required this.index,
    required this.currentStep,
    required this.data,
    required this.onTap,
  });

  final int index;
  final int currentStep;
  final AccountingWizardStep data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = index == currentStep;
    final done = index < currentStep;

    return Card(
      elevation: 0,
      color: active ? Colors.white : const Color(0xFFF8FAFC),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: active || done
                        ? const Color(0xFF10B981)
                        : const Color(0xFFE2E8F0),
                    child: Icon(
                      done
                          ? Icons.check_rounded
                          : active
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 18,
                      color: active || done
                          ? Colors.white
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      data.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      data.subtitle,
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              if (active) ...[const SizedBox(height: 14), data.child],
            ],
          ),
        ),
      ),
    );
  }
}

class _CatalogTile extends StatelessWidget {
  const _CatalogTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final AccountingCatalogOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: selected,
      selectedTileColor: const Color(0xFFEFFBF4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
        ),
      ),
      title: Text(
        option.title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: option.amountLabel.isEmpty ? null : Text(option.amountLabel),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981))
          : const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
