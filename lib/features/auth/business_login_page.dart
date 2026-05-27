import 'package:flutter/material.dart';

import 'fix_login_gate_page.dart';

class BusinessLoginPage extends StatelessWidget {
  const BusinessLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FixLoginGatePage(startCorporate: true);
  }
}
