import 'package:flutter/material.dart';

class FixLoginBrandArea extends StatelessWidget {
  const FixLoginBrandArea({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bannerHeight = (constraints.maxWidth * 0.32)
            .clamp(108.0, 138.0)
            .toDouble();

        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.asset(
            'assets/images/fix_login_hero_banner.png',
            width: double.infinity,
            height: bannerHeight,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (_, __, ___) => const _FallbackBrand(),
          ),
        );
      },
    );
  }
}

class FixWordmark extends StatelessWidget {
  const FixWordmark({super.key, this.fontSize = 56});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'fi',
            style: TextStyle(
              color: const Color(0xFF212529),
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
              height: 1,
            ),
          ),
          TextSpan(
            text: 'x',
            style: TextStyle(
              color: const Color(0xFF1DB954),
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class FixVerifiedWordmark extends StatelessWidget {
  const FixVerifiedWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    return const FixAmblemMark(height: 38, width: 70);
  }
}

class FixAmblemMark extends StatelessWidget {
  const FixAmblemMark({
    super.key,
    this.height = 38,
    this.width,
  });

  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'fix',
      child: Image.asset(
        'assets/images/fix_amblem.png',
        height: height,
        width: width,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => FixWordmark(fontSize: height * 0.86),
      ),
    );
  }
}

class FixUserInitialAvatar extends StatelessWidget {
  const FixUserInitialAvatar({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE9FFF4), Color(0xFFD7F4FF)],
        ),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF17384A).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _initial(name),
          style: const TextStyle(
            color: Color(0xFF17384A),
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  static String _initial(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'F';

    return trimmed.characters.first.toUpperCase();
  }
}

class _FallbackBrand extends StatelessWidget {
  const _FallbackBrand();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        FixWordmark(),
        SizedBox(height: 6),
        Text(
          'Çözüm ortağınız',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6C757D),
          ),
        ),
      ],
    );
  }
}
