import 'package:flutter/foundation.dart';

import 'fix_shell_nav_state.dart';

class FixSessionGate {
  const FixSessionGate._();

  static final ValueNotifier<bool> guestMode = ValueNotifier<bool>(false);
  static final ValueNotifier<int> sessionVersion = ValueNotifier<int>(0);

  static void bumpSession() {
    sessionVersion.value = sessionVersion.value + 1;
  }

  static void continueAsGuest() {
    guestMode.value = true;
    bumpSession();
  }

  static void resetGuest() {
    guestMode.value = false;
    bumpSession();
  }

  static void refreshAfterAuthChange() {
    guestMode.value = false;
    FixShellNavState.resetForAuthExit();
    bumpSession();
  }
}
