part of 'home_explore_filter_widgets.dart';

class HomeExploreControlPanel<T> extends StatelessWidget {
  const HomeExploreControlPanel({
    super.key,
    required this.hasPosition,
    required this.loadingLocation,
    required this.radiusKm,
    required this.onLocationPressed,
    required this.onRadiusChanged,
    required this.onRadiusChangeEnd,
    required this.sortModes,
    required this.selectedSortMode,
    required this.sortLabelBuilder,
    required this.onSortSelected,
    this.sortIconBuilder,
    this.primarySortMode,
    this.primarySortLabel,
  });

  final bool hasPosition;
  final bool loadingLocation;
  final double radiusKm;
  final VoidCallback onLocationPressed;
  final ValueChanged<double> onRadiusChanged;
  final ValueChanged<double> onRadiusChangeEnd;
  final List<T> sortModes;
  final T selectedSortMode;
  final String Function(T mode) sortLabelBuilder;
  final IconData Function(T mode)? sortIconBuilder;
  final ValueChanged<T> onSortSelected;
  final T? primarySortMode;
  final String? primarySortLabel;

  @override
  Widget build(BuildContext context) {
    final title = hasPosition ? 'Yakınındaki işletmeler' : 'Kayıtlı işletmeler';
    final subtitle = hasPosition
        ? 'Seçili kilometre içindeki kayıtlı işletmeler öne çıkar'
        : 'Konumdan bağımsız tüm kayıtlı işletmeler listelenir';
    final visibleSortModes = sortModes
        .where((mode) => primarySortMode == null || mode != primarySortMode)
        .toList(growable: false);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1ECEB)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF17384A).withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9FFF4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  hasPosition
                      ? Icons.near_me_outlined
                      : Icons.location_city_outlined,
                  color: const Color(0xFF216A6D),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF17384A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: loadingLocation ? null : onLocationPressed,
                icon: Icon(
                  loadingLocation
                      ? Icons.sync_rounded
                      : Icons.my_location_outlined,
                  size: 17,
                ),
                label: Text(loadingLocation ? 'Alınıyor' : 'Konum al'),
                style: FilledButton.styleFrom(
                  foregroundColor: const Color(0xFF216A6D),
                  backgroundColor: const Color(0xFFE9FFF4),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _RadiusBadge(value: radiusKm),
              Expanded(
                child: Slider(
                  min: 1,
                  max: 50,
                  divisions: 49,
                  value: radiusKm,
                  activeColor: const Color(0xFF216A6D),
                  inactiveColor: const Color(0xFFDDEBEA),
                  onChanged: onRadiusChanged,
                  onChangeEnd: onRadiusChangeEnd,
                ),
              ),
            ],
          ),
          if (primarySortMode != null) ...[
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: loadingLocation
                    ? null
                    : () {
                        if (!hasPosition) {
                          onLocationPressed();
                          return;
                        }
                        onSortSelected(primarySortMode as T);
                      },
                style: FilledButton.styleFrom(
                  backgroundColor:
                      primarySortMode == selectedSortMode && hasPosition
                      ? const Color(0xFF216A6D)
                      : const Color(0xFFE9FFF4),
                  foregroundColor:
                      primarySortMode == selectedSortMode && hasPosition
                      ? Colors.white
                      : const Color(0xFF216A6D),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  loadingLocation
                      ? 'Konum alınıyor'
                      : primarySortLabel ??
                            (hasPosition
                                ? 'Konuma göre sırala'
                                : 'Konum al ve sırala'),
                ),
              ),
            ),
            const SizedBox(height: 9),
          ],
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: visibleSortModes.length,
              separatorBuilder: (_, _) => const SizedBox(width: 7),
              itemBuilder: (context, index) {
                final mode = visibleSortModes[index];
                final selected = mode == selectedSortMode;
                final icon = sortIconBuilder?.call(mode);

                return ChoiceChip(
                  selected: selected,
                  onSelected: (_) => onSortSelected(mode),
                  avatar: icon == null
                      ? null
                      : Icon(
                          icon,
                          size: 15,
                          color: selected
                              ? Colors.white
                              : const Color(0xFF60727A),
                        ),
                  label: Text(sortLabelBuilder(mode)),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF60727A),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                  selectedColor: const Color(0xFF216A6D),
                  backgroundColor: const Color(0xFFF5FAFA),
                  side: BorderSide(
                    color: selected
                        ? const Color(0xFF216A6D)
                        : const Color(0xFFE1ECEB),
                  ),
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
