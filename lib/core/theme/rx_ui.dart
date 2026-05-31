import 'package:flutter/material.dart';

part 'rx_ui_buttons_part.dart';
part 'rx_ui_tiles_part.dart';
part 'rx_ui_states_part.dart';

class RxColors {
  static const Color background = Color(0xFFF6F7FB);
  static const Color surface = Colors.white;
  static const Color primary = Color(0xFF18B7C9);
  static const Color navy = Color(0xFF0B1F3A);
  static const Color green = Color(0xFF10B981);
  static const Color success = Color(0xFF1D9E75);
  static const Color warning = Color(0xFFBA7517);
  static const Color danger = Color(0xFFA32D2D);
  static const Color premium = Color(0xFF534AB7);
  static const Color red = Color(0xFFEF4444);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color orange = Color(0xFFF59E0B);
  static const Color text = Color(0xFF111827);
  static const Color muted = Color(0xFF6B7280);
  static const Color line = Color(0xFFE5E7EB);
}

class RxSpace {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
}

class RxRadius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 26;
}

class RxText {
  static const TextStyle pageTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w900,
    color: RxColors.text,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w900,
    color: RxColors.text,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    color: RxColors.text,
  );

  static const TextStyle body = TextStyle(
    fontSize: 13,
    color: RxColors.muted,
    height: 1.25,
  );

  static const TextStyle tiny = TextStyle(
    fontSize: 11,
    color: RxColors.muted,
    fontWeight: FontWeight.w700,
  );
}
