/// Central place for all third-party keys and ad unit IDs.
///
/// Fill in the TODO values before publishing. Keep this file the single source
/// of truth so keys are never scattered across the codebase.
class AppConfig {
  // --- AdMob -----------------------------------------------------------------
  // App ID (from AdMob dashboard, per platform).
  static const String androidAdMobAppId =
      'ca-app-pub-3940256099942544~3347511713'; // TODO: replace with real Android App ID
  static const String iosAdMobAppId =
      'ca-app-pub-5032421313412543~6390489383';

  // Banner ad units.
  static const String androidBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111'; // TODO: replace with real Android banner unit
  static const String iosBannerAdUnitId =
      'ca-app-pub-5032421313412543/2259672689';

  // Interstitial ad units.
  static const String androidInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712'; // TODO: replace with real Android interstitial unit
  static const String iosInterstitialAdUnitId =
      'ca-app-pub-5032421313412543/1889685753';

  // --- RevenueCat ------------------------------------------------------------
  // SDK keys (public; safe to ship). "Test Store" key below is a RevenueCat
  // TEST key and works for sandbox purchases.
  static const String revenueCatAppleKey =
      'test_rHdamOwgUNHvEyLavASbMhSYXyD'; // Test Store (iOS) key
  static const String revenueCatGoogleKey =
      'test_rHdamOwgUNHvEyLavASbMhSYXyD'; // TODO: replace with a real Google/Play key once an Android app is created in RevenueCat

  /// Entitlement identifier as configured in the RevenueCat dashboard.
  /// Currently: "Dollars to Yuan Pro"
  static const String premiumEntitlementId = 'Dollars to Yuan Pro';

  /// Package identifiers we expect inside the current offering.
  /// Derived from the RevenueCat dashboard ($rc_monthly / $rc_annual).
  static const String monthlyPackageId = '\$rc_monthly';
  static const String yearlyPackageId = '\$rc_annual';
}
