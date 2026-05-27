import 'package:flutter/material.dart';

/// Bireysel kullanici Hesabim govdesi icin guvenli iskelet.
///
/// Not:
/// Bu dosya 48B-B2-S1 asamasinda henuz account_entry_page.dart tarafindan
/// kullanilmaz. Sonraki patchte mevcut bireysel govde parca parca buraya
/// tasinacaktir.
class IndividualAccountBody extends StatelessWidget {
  const IndividualAccountBody({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
