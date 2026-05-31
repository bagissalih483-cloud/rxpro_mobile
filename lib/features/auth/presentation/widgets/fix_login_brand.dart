import 'package:flutter/material.dart';

class FixLoginBrandArea extends StatelessWidget {
  const FixLoginBrandArea({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bannerHeight = (constraints.maxWidth * 0.24)
            .clamp(76.0, 96.0)
            .toDouble();

        return Container(
          height: bannerHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF7FFF9), Color(0xFFE6F7EE)],
            ),
            border: Border.all(color: Color(0xFFDCEBE4)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF17384A).withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.18,
                  child: Image.asset(
                    'assets/images/fix_login_hero_banner.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 13, 16, 12),
                child: Row(
                  children: [
                    const FixAmblemMark(height: 42, width: 84),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Randevu ve işletme yönetimi',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF17384A),
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Tek panelde güvenli erişim',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFDCEBE4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            color: Color(0xFF1DB954),
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Güvenli',
                            style: TextStyle(
                              color: Color(0xFF25643A),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
  const FixAmblemMark({super.key, this.height = 38, this.width});

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
        errorBuilder: (context, error, stackTrace) =>
            FixWordmark(fontSize: height * 0.86),
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
