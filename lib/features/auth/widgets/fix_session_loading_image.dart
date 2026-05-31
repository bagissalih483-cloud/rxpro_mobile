import 'dart:math' as math;
import 'package:flutter/material.dart';

class FixSessionLoadingImage extends StatelessWidget {
  const FixSessionLoadingImage({
    super.key,
    this.message = 'Hesabın yükleniyor...',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final logoSide = math.min(size.width * 0.78, 360.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: logoSide,
                  height: logoSide,
                  child: Image.asset(
                    'assets/images/fix_session_loading.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const SizedBox(height: 14),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.6),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Fix',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Yakındaki güvenilir işletmeleri keşfet. Randevunu kolayca al.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
