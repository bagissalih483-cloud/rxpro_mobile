import 'package:flutter/foundation.dart';

class FixShellNavState {
  const FixShellNavState._();

  static int guestIndex = 0;
  static int individualIndex = 0;
  static int corporateIndex = 0;

  static final ValueNotifier<int> guestIndexNotifier = ValueNotifier<int>(0);
  static final ValueNotifier<int> individualIndexNotifier =
      ValueNotifier<int>(0);
  static final ValueNotifier<int> corporateIndexNotifier =
      ValueNotifier<int>(0);

  static void setGuestIndex(int index) {
    guestIndex = index;
    if (guestIndexNotifier.value != index) {
      guestIndexNotifier.value = index;
    }
  }

  static void setIndividualIndex(int index) {
    individualIndex = index;
    if (individualIndexNotifier.value != index) {
      individualIndexNotifier.value = index;
    }
  }

  static void setCorporateIndex(int index) {
    corporateIndex = index;
    if (corporateIndexNotifier.value != index) {
      corporateIndexNotifier.value = index;
    }
  }

  static void resetAll() {
    setGuestIndex(0);
    setIndividualIndex(0);
    setCorporateIndex(0);
  }

  static void resetForAuthExit() {
    resetAll();
  }
}
