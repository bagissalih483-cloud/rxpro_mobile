import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';

class BusinessProfileEditButton extends StatelessWidget {
  final String businessId;
  final VoidCallback? onUpdated;

  const BusinessProfileEditButton({
    super.key,
    required this.businessId,
    this.onUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final updated = await Navigator.of(context).pushNamed<bool>(
          AppRoutes.businessProfileEdit,
          arguments: BusinessProfileEditRouteArgs(businessId: businessId),
        );

        if (updated == true) {
          onUpdated?.call();

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profil bilgileri yenilendi.')),
            );
          }
        }
      },
      icon: const Icon(Icons.edit_rounded),
      label: const Text('Profili Düzenle'),
    );
  }
}
