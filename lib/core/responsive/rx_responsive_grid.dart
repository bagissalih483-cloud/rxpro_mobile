import 'dart:math' as math;

import 'package:flutter/widgets.dart';

class RxResponsiveGrid extends StatelessWidget {
  const RxResponsiveGrid({
    super.key,
    this.itemCount,
    this.itemBuilder,
    this.children,
    this.minItemWidth = 360,
    this.spacing = 12,
    this.maxColumns = 3,
  }) : assert(
         children != null || (itemCount != null && itemBuilder != null),
         'Provide either children or itemCount with itemBuilder.',
       );

  final int? itemCount;
  final IndexedWidgetBuilder? itemBuilder;
  final List<Widget>? children;
  final double minItemWidth;
  final double spacing;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    final resolvedItemCount = children?.length ?? itemCount ?? 0;
    Widget buildItem(BuildContext context, int index) {
      final resolvedChildren = children;
      if (resolvedChildren != null) return resolvedChildren[index];
      return itemBuilder!(context, index);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final rawColumns = constraints.maxWidth ~/ minItemWidth;
        final columns = math.max(1, math.min(maxColumns, rawColumns));

        if (columns == 1) {
          return Column(
            children: [
              for (var index = 0; index < resolvedItemCount; index++)
                buildItem(context, index),
            ],
          );
        }

        final width =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var index = 0; index < resolvedItemCount; index++)
              SizedBox(width: width, child: buildItem(context, index)),
          ],
        );
      },
    );
  }
}
