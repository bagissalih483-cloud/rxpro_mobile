import 'package:flutter/widgets.dart';

class AccountingWizardStep {
  const AccountingWizardStep({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;
}

class AccountingCatalogOption {
  const AccountingCatalogOption(this.id, this.title, this.amountLabel);

  final String id;
  final String title;
  final String amountLabel;
}
