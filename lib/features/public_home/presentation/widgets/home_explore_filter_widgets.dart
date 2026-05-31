import 'package:flutter/material.dart';

import '../../../../core/theme/rx_ui.dart';
import '../models/home_explore_category_style.dart';

part 'home_explore_control_panel_part.dart';
part 'home_explore_radius_badge_part.dart';

class HomeExploreSearchBox extends StatelessWidget {
  const HomeExploreSearchBox({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        hintText: 'İşletme, kategori veya ilçe ara',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.trim().isEmpty
            ? null
            : IconButton(onPressed: onClear, icon: const Icon(Icons.close)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        border: _border,
        enabledBorder: _border,
      ),
    );
  }

  static final OutlineInputBorder _border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: const BorderSide(color: Color(0xFFE1ECEB)),
  );
}

class HomeExploreCategoryRow extends StatelessWidget {
  const HomeExploreCategoryRow({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
    this.counts = const <String, int>{},
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;
  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = selectedCategory == category;
          final count = counts[category] ?? 0;
          final style = HomeExploreCategoryStyles.forLabel(category);

          return OutlinedButton(
            onPressed: () => onSelected(category),
            style: OutlinedButton.styleFrom(
              backgroundColor: selected
                  ? style.background
                  : Color.lerp(style.background, Colors.white, 0.58),
              foregroundColor: selected
                  ? style.accent
                  : const Color(0xFF60727A),
              side: BorderSide(color: selected ? style.accent : style.border),
              padding: const EdgeInsets.symmetric(horizontal: 13),
              minimumSize: const Size(0, 38),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(style.icon, size: 15),
                const SizedBox(width: 5),
                Text(category, style: const TextStyle(fontSize: 12)),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  RxStatusChip(
                    label: count > 99 ? '99+' : '$count',
                    color: selected ? style.accent : RxColors.muted,
                    compact: true,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
