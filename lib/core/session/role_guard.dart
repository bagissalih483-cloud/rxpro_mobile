import 'package:flutter/material.dart';

import 'app_role.dart';
import 'app_session.dart';

class RoleGuard extends StatelessWidget {
  const RoleGuard({
    super.key,
    required this.session,
    required this.allowedRoles,
    required this.child,
    this.fallback,
    this.title,
    this.description,
  });

  final AppSession session;
  final Set<AppRole> allowedRoles;
  final Widget child;
  final Widget? fallback;
  final String? title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    if (allowedRoles.contains(session.role)) {
      return child;
    }

    return fallback ??
        RoleAccessDeniedCard(
          title: title ?? 'Bu alan için giriş yetkisi gerekli',
          description:
              description ??
              'Bu sayfaya erişmek için uygun kullanıcı tipiyle giriş yapmalısınız.',
        );
  }
}

class PermissionGuard extends StatelessWidget {
  const PermissionGuard({
    super.key,
    required this.session,
    required this.permissionKey,
    required this.child,
    this.fallback,
    this.title,
    this.description,
  });

  final AppSession session;
  final String permissionKey;
  final Widget child;
  final Widget? fallback;
  final String? title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    if (session.hasPermission(permissionKey)) {
      return child;
    }

    return fallback ??
        RoleAccessDeniedCard(
          title: title ?? 'Yetki gerekli',
          description:
              description ??
              'Kurumsal personel hesabınızda bu işlem için yetki tanımlı değil.',
        );
  }
}

class RoleAccessDeniedCard extends StatelessWidget {
  const RoleAccessDeniedCard({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 42,
                  color: Color(0xFF1DB954),
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
                const SizedBox(height: 10),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.35,
                    color: Color(0xFF6C757D),
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
