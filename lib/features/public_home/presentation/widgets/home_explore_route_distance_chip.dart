import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rxpro_mobile/core/businesses/business_directory_cache_service.dart';
import 'package:rxpro_mobile/core/businesses/business_route_distance_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_explore_route_distance_controller.dart';

class HomeExploreRouteDistanceChip extends StatefulWidget {
  const HomeExploreRouteDistanceChip({
    super.key,
    required this.business,
    required this.origin,
    required this.color,
    this.enabled = true,
  });

  final BusinessDirectoryItem business;
  final Position? origin;
  final Color color;
  final bool enabled;

  @override
  State<HomeExploreRouteDistanceChip> createState() =>
      _HomeExploreRouteDistanceChipState();
}

class _HomeExploreRouteDistanceChipState
    extends State<HomeExploreRouteDistanceChip> {
  static final BusinessRouteDistanceService _service =
      BusinessRouteDistanceService();
  static const String _routeDistancePreferenceKey =
      'fix_settings_route_distance_enabled';

  final HomeExploreRouteDistanceController _controller =
      HomeExploreRouteDistanceController();

  @override
  void initState() {
    super.initState();
    _startLoadIfNeeded();
  }

  @override
  void didUpdateWidget(HomeExploreRouteDistanceChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.resetForKey(_routeKey());
    _startLoadIfNeeded();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled ||
        widget.origin == null ||
        !widget.business.hasCoordinate) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final info = _controller.info;
        if (info != null) {
          return _RouteChip(
            icon: Icons.route_outlined,
            label: info.summaryLabel,
            color: widget.color,
          );
        }

        if (_controller.loading) {
          return _RouteChip(
            icon: Icons.sync_rounded,
            label: 'Rota hesaplanıyor',
            color: widget.color,
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  void _startLoadIfNeeded() {
    if (!widget.enabled ||
        widget.origin == null ||
        !widget.business.hasCoordinate ||
        _controller.loading ||
        _controller.attempted) {
      return;
    }

    final key = _routeKey();
    if (_controller.beginAttempt(key)) {
      _calculateIfAllowed(key);
    }
  }

  Future<void> _calculateIfAllowed(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted || key != _controller.activeKey) return;

      if (prefs.getBool(_routeDistancePreferenceKey) == false) {
        _controller.markSkipped();
        return;
      }

      final info = await _service.calculate(
        origin: widget.origin,
        business: widget.business,
      );
      if (!mounted || key != _controller.activeKey) return;
      _controller.complete(info);
    } catch (_) {
      if (!mounted || key != _controller.activeKey) return;
      _controller.markSkipped();
    }
  }

  String _routeKey() {
    final origin = widget.origin;
    return [
      widget.enabled,
      origin?.latitude.toStringAsFixed(3) ?? '',
      origin?.longitude.toStringAsFixed(3) ?? '',
      widget.business.placeId,
      widget.business.lat?.toStringAsFixed(5) ?? '',
      widget.business.lng?.toStringAsFixed(5) ?? '',
    ].join(':');
  }
}

class _RouteChip extends StatelessWidget {
  const _RouteChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
