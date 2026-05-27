import 'package:flutter/material.dart';

class FixLoginGuestActions extends StatelessWidget {
  const FixLoginGuestActions({
    super.key,
    required this.loading,
    required this.onGuest,
    required this.onForgot,
  });

  final bool loading;
  final VoidCallback onGuest;
  final VoidCallback onForgot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        border: Border(top: BorderSide(color: Color(0xFFE9ECEF))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton(
                onPressed: loading ? null : onGuest,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF212529),
                  side: const BorderSide(color: Color(0xFFCED4DA)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'Misafir olarak devam et',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: loading ? null : onForgot,
              child: const Text(
                'Şifremi Unuttum',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6C757D),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
