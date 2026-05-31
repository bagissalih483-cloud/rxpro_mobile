import 'package:flutter/material.dart';

class FixLoginGuestActions extends StatelessWidget {
  const FixLoginGuestActions({
    super.key,
    required this.loading,
    required this.onGuest,
  });

  final bool loading;
  final VoidCallback onGuest;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton(
              onPressed: loading ? null : onGuest,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF17384A),
                side: const BorderSide(color: Color(0xFFDCE7E6)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Üye olmadan keşfet',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Devam ederek Kullanım Şartları ve Gizlilik Politikası’nı kabul etmiş olursunuz.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10.5,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
