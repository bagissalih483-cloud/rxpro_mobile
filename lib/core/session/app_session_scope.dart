import 'package:flutter/widgets.dart';

import 'app_session.dart';

class AppSessionScope extends InheritedWidget {
  const AppSessionScope({
    super.key,
    required this.session,
    required super.child,
  });

  final AppSession session;

  static AppSession? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppSessionScope>();
    return scope?.session;
  }

  static AppSession of(BuildContext context) {
    final session = maybeOf(context);
    assert(session != null, 'AppSessionScope bulunamadı.');
    return session!;
  }

  @override
  bool updateShouldNotify(AppSessionScope oldWidget) {
    return oldWidget.session.uid != session.uid ||
        oldWidget.session.role != session.role ||
        oldWidget.session.businessId != session.businessId ||
        oldWidget.session.businessName != session.businessName;
  }
}
