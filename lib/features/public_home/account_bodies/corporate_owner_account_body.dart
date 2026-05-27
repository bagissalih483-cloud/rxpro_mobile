import 'package:flutter/material.dart';

/// Kurumsal owner Hesabim govdesi icin guvenli iskelet.
///
/// Not:
/// Bu dosya 48B-B2-S1 asamasinda henuz account_entry_page.dart tarafindan
/// kullanilmaz. Sonraki patchte mevcut kurumsal owner govde parca parca
/// buraya tasinacaktir.
class CorporateOwnerAccountBody extends StatelessWidget {
  const CorporateOwnerAccountBody({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
