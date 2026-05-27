import 'package:flutter/material.dart';

import 'package:rxpro_mobile/core/session/app_role.dart';
import 'package:rxpro_mobile/core/session/session_role_gate.dart';

import 'package:rxpro_mobile/features/business_analysis/business_analysis_page.dart';
import 'package:rxpro_mobile/features/business_role/business_role_resolver.dart';
import 'package:rxpro_mobile/features/favorites/favorite_feed_page.dart';

class FavoriteEntryPage extends StatefulWidget {
  const FavoriteEntryPage({super.key});

  @override
  State<FavoriteEntryPage> createState() => _FavoriteEntryPageState();
}

class _FavoriteEntryPageState extends State<FavoriteEntryPage> {
  late Future<BusinessRoleResult> future;

  @override
  void initState() {
    super.initState();
    future = BusinessRoleResolver.resolveCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BusinessRoleResult>(
      future: future,
      builder: (context, snapshot) {
        final role = snapshot.data;

        if (role == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!role.isBusiness) {
          return const SessionRoleGate(
            allowedRoles: {AppRole.individual},
            title: 'Favoriler bireysel kullanıcı alanıdır',
            description:
                'Favori ve takip akışı sadece bireysel kullanıcı hesabıyla kullanılabilir.',
            child: FavoriteFeedPage(),
          );
        }

        return BusinessAnalysisPage(
          businessId: role.businessId,
          businessName: role.businessName,
        );
      },
    );
  }
}
