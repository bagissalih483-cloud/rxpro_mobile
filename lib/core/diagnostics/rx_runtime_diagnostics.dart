class RxRuntimeDiagnostics {
  const RxRuntimeDiagnostics._();

  static const bool safeBoot = bool.fromEnvironment('RXPRO_SAFE_BOOT');
  static const bool disableExploreAutoLoad = bool.fromEnvironment(
    'RXPRO_DISABLE_EXPLORE_AUTO_LOAD',
  );
  static const bool disableDeferredStartup = bool.fromEnvironment(
    'RXPRO_DISABLE_DEFERRED_STARTUP',
  );
  static const bool disablePushTokenCleanup = bool.fromEnvironment(
    'RXPRO_DISABLE_PUSH_TOKEN_CLEANUP',
  );
  static const bool verboseExploreRender = bool.fromEnvironment(
    'RXPRO_VERBOSE_EXPLORE_RENDER',
  );

  static bool get shouldSkipDeferredStartup =>
      safeBoot || disableDeferredStartup;

  static bool get shouldSkipPushTokenCleanup =>
      safeBoot || disablePushTokenCleanup;
}
