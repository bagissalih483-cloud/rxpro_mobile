import 'dart:async';
import 'package:rxpro_mobile/features/auth/widgets/fix_session_loading_image.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'app/app_route_catalog.dart';
import 'app/fix_bootstrap_controller.dart';
import 'app/main_shell_controller.dart';
import 'app/role_gate_controller.dart';
import 'package:rxpro_mobile/core/session/session_role_gate.dart';
import 'package:rxpro_mobile/core/session/app_session_scope.dart';
import 'package:rxpro_mobile/core/session/app_role.dart';
import 'core/theme/rx_ui.dart';
import 'core/responsive/rx_adaptive_app_frame.dart';
import 'core/responsive/rx_adaptive_shell_scaffold.dart';
import 'core/responsive/rx_adaptive_scroll_behavior.dart';
import 'core/responsive/rx_orientation_policy.dart';
import 'core/diagnostics/rx_runtime_diagnostics.dart';
import 'core/app_state/follow_cache_warmup_service.dart';
import 'core/app_state/fix_session_gate.dart';
import 'core/app_state/fix_shell_nav_state.dart';
import 'core/services/app_observability_service.dart';
import 'core/services/auth_service.dart';
import 'core/security/firebase_app_check_bootstrap.dart';
import 'core/session/app_session.dart';
import 'core/session/app_session_controller.dart';
import 'core/realtime/rx_push_notification_service.dart';
import 'features/appointments/presentation/pages/appointment_entry_page.dart';
import 'features/appointments/presentation/pages/customer_appointments_page.dart';
import 'features/business_role/business_role_resolver.dart';
import 'features/businesses/business_management_home_page.dart';
import 'features/campaigns/business_marketing_hub_page.dart';
import 'features/campaigns/customer_campaigns_page.dart';
import 'features/favorites/favorite_feed_page.dart';
import 'features/public_home/presentation/pages/account_entry_page.dart';
import 'features/auth/fix_login_gate_page.dart';
import 'features/accounting/business_accounting_shell.dart';
import 'features/public_home/home_explore_page.dart';
import 'features/public_home/guest_feature_preview_page.dart';

part 'app/fix_bootstrap_app.dart';
part 'app/role_gate_shell.dart';
part 'app/main_shells.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      if (kReleaseMode) {
        debugPrint = (String? message, {int? wrapWidth}) {};
      }

      unawaited(RxOrientationPolicy.applyStartupPolicy());

      runApp(const FixBootstrapApp());
    },
    (error, stackTrace) {
      unawaited(
        AppObservabilityService.instance.recordError(
          error,
          stackTrace,
          fatal: true,
          reason: 'Uncaught root zone error',
        ),
      );
    },
  );
}
