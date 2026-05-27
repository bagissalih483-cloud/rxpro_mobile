import 'package:rxpro_mobile/features/auth/widgets/fix_session_loading_image.dart';
import 'package:flutter/material.dart';
import 'package:rxpro_mobile/core/services/auth_service.dart';

import 'app_role.dart';
import 'app_session.dart';
import 'app_session_controller.dart';
import 'app_session_scope.dart';
import 'role_guard.dart';

class SessionRoleGate extends StatelessWidget {
  const SessionRoleGate({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.permissionKey,
    this.title,
    this.description,
    this.guestFallback,
  });

  final Set<AppRole> allowedRoles;
  final Widget child;
  final String? permissionKey;
  final String? title;
  final String? description;
  final Widget? guestFallback;
  static final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final scopedSession = AppSessionScope.maybeOf(context);

    if (scopedSession != null) {
      return _buildForSession(scopedSession);
    }

    final user = _authService.currentUser;

    if (user == null) {
      return guestFallback ??
          RoleAccessDeniedCard(
            title: title ?? 'Giriş gerekli',
            description:
                description ??
                'Bu alanı kullanmak için bireysel veya kurumsal hesabınızla giriş yapmalısınız.',
          );
    }

    return StreamBuilder<AppSession>(
      stream: AppSessionController.watchForUser(user),
      builder: (context, snapshot) {
        final session = snapshot.data;

        if (session == null) {
          return const _SoftSessionLoading();
        }

        return _buildForSession(session);
      },
    );
  }

  Widget _buildForSession(AppSession session) {
    if (!allowedRoles.contains(session.role)) {
      return RoleAccessDeniedCard(
        title: title ?? 'Bu alan için yetkiniz yok',
        description:
            description ?? 'Bu sayfa mevcut kullanıcı tipiniz için kapalıdır.',
      );
    }

    final permission = permissionKey;

    if (permission != null &&
        permission.trim().isNotEmpty &&
        !session.hasPermission(permission)) {
      return RoleAccessDeniedCard(
        title: 'Yetki gerekli',
        description:
            'Kurumsal personel hesabınızda bu işlem için yetki tanımlı değil.',
      );
    }

    return child;
  }
}

class GuestPromoGate extends StatelessWidget {
  const GuestPromoGate({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.bullets,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 44, color: const Color(0xFF1DB954)),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
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
                const SizedBox(height: 16),
                ...bullets.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: Color(0xFF1DB954),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.25,
                              color: Color(0xFF343A40),
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _SoftSessionLoading extends StatelessWidget {
  const _SoftSessionLoading();

  @override
  Widget build(BuildContext context) {
    return const FixSessionLoadingImage();
  }
}
