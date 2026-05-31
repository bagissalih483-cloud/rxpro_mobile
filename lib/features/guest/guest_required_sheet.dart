import 'package:flutter/material.dart';

import '../../core/app_state/fix_session_gate.dart';
import '../../core/responsive/rx_adaptive_modal.dart';

class GuestRequiredSheet {
  const GuestRequiredSheet._();

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showRxAdaptiveModal<void>(
      context: context,
      desktopMaxWidth: 440,
      builder: (_) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFFEFFAF3),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    color: Color(0xFF1DB954),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF212529),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Color(0xFF6C757D),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      FixSessionGate.resetGuest();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1DB954),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'Giriş yap veya hesap oluştur',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Şimdilik keşfetmeye devam et'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
