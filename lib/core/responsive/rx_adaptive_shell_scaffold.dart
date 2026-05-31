import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/rx_ui.dart';
import 'rx_navigation_policy.dart';

class RxAdaptiveShellScaffold extends StatelessWidget {
  const RxAdaptiveShellScaffold({
    super.key,
    required this.selectedIndex,
    required this.titles,
    required this.pages,
    required this.destinations,
    required this.onSelected,
    this.onBackPressed,
    this.showTabletMiniDock = true,
    this.tabletMiniDockHiddenTitles = const <String>{},
  });

  final int selectedIndex;
  final List<String> titles;
  final List<Widget> pages;
  final List<NavigationDestination> destinations;
  final ValueChanged<int> onSelected;
  final Future<bool> Function(int safeIndex)? onBackPressed;
  final bool showTabletMiniDock;
  final Set<String> tabletMiniDockHiddenTitles;

  @override
  Widget build(BuildContext context) {
    final safeIndex = selectedIndex.clamp(0, pages.length - 1);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldExit = await onBackPressed?.call(safeIndex) ?? false;
        if (shouldExit) {
          await SystemNavigator.pop();
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final policy = RxNavigationPolicy.fromWidth(constraints.maxWidth);

          if (!policy.useSideNavigation) {
            return Scaffold(
              appBar: AppBar(
                title: _ShellTitle(text: titles[safeIndex]),
                centerTitle: false,
              ),
              body: _LazyShellStack(index: safeIndex, pages: pages),
              bottomNavigationBar: NavigationBar(
                selectedIndex: safeIndex,
                onDestinationSelected: onSelected,
                destinations: destinations,
              ),
            );
          }

          final showDock =
              showTabletMiniDock &&
              (policy.deviceClass.isSmallTablet ||
                  policy.deviceClass.isTablet) &&
              !tabletMiniDockHiddenTitles.contains(titles[safeIndex]);

          return Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  _ShellNavigationRail(
                    selectedIndex: safeIndex,
                    extended: policy.extendSideNavigation,
                    destinations: destinations,
                    onSelected: onSelected,
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                  Expanded(
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            _WideShellHeader(title: titles[safeIndex]),
                            Expanded(
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: policy.contentMaxWidth,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: policy.horizontalPadding,
                                    ),
                                    child: _LazyShellStack(
                                      index: safeIndex,
                                      pages: pages,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (showDock)
                          Positioned.fill(
                            child: _TabletMiniDock(
                              selectedIndex: safeIndex,
                              destinations: destinations,
                              onSelected: onSelected,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ShellNavigationRail extends StatelessWidget {
  const _ShellNavigationRail({
    required this.selectedIndex,
    required this.extended,
    required this.destinations,
    required this.onSelected,
  });

  final int selectedIndex;
  final bool extended;
  final List<NavigationDestination> destinations;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      extended: extended,
      minWidth: 76,
      minExtendedWidth: 226,
      backgroundColor: RxColors.surface,
      labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
      leading: const Padding(
        padding: EdgeInsets.fromLTRB(8, 12, 8, 18),
        child: _RailBrand(),
      ),
      onDestinationSelected: onSelected,
      destinations: destinations
          .map(
            (destination) => NavigationRailDestination(
              icon: destination.icon,
              selectedIcon: destination.selectedIcon,
              label: Text(destination.label),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _RailBrand extends StatelessWidget {
  const _RailBrand();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: RxColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const SizedBox(
        width: 42,
        height: 42,
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Image(
            image: AssetImage('assets/images/fix_amblem.png'),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _WideShellHeader extends StatelessWidget {
  const _WideShellHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: const BoxDecoration(
        color: RxColors.background,
        border: Border(bottom: BorderSide(color: RxColors.line)),
      ),
      child: _ShellTitle(text: title),
    );
  }
}

class _ShellTitle extends StatelessWidget {
  const _ShellTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w900));
  }
}

class _TabletMiniDock extends StatefulWidget {
  const _TabletMiniDock({
    required this.selectedIndex,
    required this.destinations,
    required this.onSelected,
  });

  final int selectedIndex;
  final List<NavigationDestination> destinations;
  final ValueChanged<int> onSelected;

  @override
  State<_TabletMiniDock> createState() => _TabletMiniDockState();
}

class _TabletMiniDockState extends State<_TabletMiniDock> {
  static const double _collapsedWidth = 46;
  static const double _collapsedHeight = 66;
  static const double _expandedWidth = 188;
  static const double _expandedItemHeight = 44;
  static const double _edgeInset = 8;

  final ValueNotifier<bool> _expanded = ValueNotifier<bool>(false);
  final ValueNotifier<Offset?> _offset = ValueNotifier<Offset?>(null);

  @override
  void dispose() {
    _expanded.dispose();
    _offset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ValueListenableBuilder<Offset?>(
          valueListenable: _offset,
          builder: (context, storedOffset, _) {
            final offset = _effectiveOffset(storedOffset, constraints);

            return ValueListenableBuilder<bool>(
              valueListenable: _expanded,
              builder: (context, expanded, _) {
                final width = expanded ? _expandedWidth : _collapsedWidth;
                final height = expanded
                    ? 56 + (widget.destinations.length * _expandedItemHeight)
                    : _collapsedHeight;
                final clampedPosition = _clampOffset(
                  offset,
                  constraints,
                  width: width,
                  height: height,
                );
                final position = expanded
                    ? clampedPosition
                    : _snapToEdge(
                        clampedPosition,
                        constraints,
                        width: width,
                        height: height,
                      );

                return Stack(
                  children: [
                    Positioned(
                      left: position.dx,
                      top: position.dy,
                      width: width,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          _offset.value = _clampOffset(
                            Offset(
                              position.dx + details.delta.dx,
                              position.dy + details.delta.dy,
                            ),
                            constraints,
                            width: width,
                            height: height,
                          );
                        },
                        onPanEnd: (_) {
                          _offset.value = _snapToEdge(
                            _offset.value ?? position,
                            constraints,
                            width: width,
                            height: height,
                          );
                        },
                        child: expanded
                            ? _ExpandedTabletDock(
                                selectedIndex: widget.selectedIndex,
                                destinations: widget.destinations,
                                onClose: () => _expanded.value = false,
                                onSelected: (index) {
                                  HapticFeedback.selectionClick();
                                  _expanded.value = false;
                                  widget.onSelected(index);
                                },
                              )
                            : _CollapsedTabletDock(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  _expanded.value = true;
                                },
                              ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Offset _effectiveOffset(Offset? storedOffset, BoxConstraints constraints) {
    if (storedOffset != null) return storedOffset;

    return Offset(
      constraints.maxWidth - _collapsedWidth - _edgeInset,
      constraints.maxHeight * 0.56,
    );
  }

  Offset _snapToEdge(
    Offset offset,
    BoxConstraints constraints, {
    required double width,
    required double height,
  }) {
    final left = offset.dx < constraints.maxWidth / 2
        ? _edgeInset
        : constraints.maxWidth - width - _edgeInset;

    return _clampOffset(
      Offset(left, offset.dy),
      constraints,
      width: width,
      height: height,
    );
  }

  Offset _clampOffset(
    Offset offset,
    BoxConstraints constraints, {
    required double width,
    required double height,
  }) {
    final maxX = (constraints.maxWidth - width - _edgeInset).clamp(
      _edgeInset,
      double.infinity,
    );
    final maxY = (constraints.maxHeight - height - _edgeInset).clamp(
      _edgeInset,
      double.infinity,
    );

    return Offset(
      offset.dx.clamp(_edgeInset, maxX).toDouble(),
      offset.dy.clamp(_edgeInset, maxY).toDouble(),
    );
  }
}

class _CollapsedTabletDock extends StatelessWidget {
  const _CollapsedTabletDock({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Hizli sekmeler',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Ink(
            height: _TabletMiniDockState._collapsedHeight,
            decoration: BoxDecoration(
              color: RxColors.primary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.apps_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpandedTabletDock extends StatelessWidget {
  const _ExpandedTabletDock({
    required this.selectedIndex,
    required this.destinations,
    required this.onClose,
    required this.onSelected,
  });

  final int selectedIndex;
  final List<NavigationDestination> destinations;
  final VoidCallback onClose;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: RxColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: RxColors.line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Hizli sekme',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: RxColors.text,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Kapat',
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              for (var index = 0; index < destinations.length; index++)
                _TabletDockDestinationTile(
                  destination: destinations[index],
                  selected: index == selectedIndex,
                  onTap: () => onSelected(index),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabletDockDestinationTile extends StatelessWidget {
  const _TabletDockDestinationTile({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavigationDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: _TabletMiniDockState._expandedItemHeight,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected
                ? RxColors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              IconTheme(
                data: IconThemeData(
                  size: 20,
                  color: selected ? RxColors.primary : RxColors.muted,
                ),
                child: selected
                    ? destination.selectedIcon ?? destination.icon
                    : destination.icon,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  destination.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? RxColors.primary : RxColors.text,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LazyShellStack extends StatefulWidget {
  const _LazyShellStack({required this.index, required this.pages});

  final int index;
  final List<Widget> pages;

  @override
  State<_LazyShellStack> createState() => _LazyShellStackState();
}

class _LazyShellStackState extends State<_LazyShellStack> {
  final Set<int> _visited = <int>{};

  @override
  void initState() {
    super.initState();
    _visited.add(widget.index);
  }

  @override
  void didUpdateWidget(covariant _LazyShellStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _visited
      ..removeWhere((index) => index >= widget.pages.length)
      ..add(widget.index);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (final index in _visited)
          Offstage(
            offstage: index != widget.index,
            child: TickerMode(
              enabled: index == widget.index,
              child: SizedBox.expand(
                child: KeyedSubtree(
                  key: PageStorageKey<String>('shell_page_$index'),
                  child: widget.pages[index],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
