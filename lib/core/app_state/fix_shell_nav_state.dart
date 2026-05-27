class FixShellNavState {
  const FixShellNavState._();

  static int guestIndex = 0;
  static int individualIndex = 0;
  static int corporateIndex = 0;

  static void resetAll() {
    guestIndex = 0;
    individualIndex = 0;
    corporateIndex = 0;
  }

  static void resetForAuthExit() {
    guestIndex = 0;
    individualIndex = 0;
    corporateIndex = 0;
  }
}
