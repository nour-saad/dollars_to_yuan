import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/app.dart';
import 'src/core/services/storage_service.dart';
import 'src/core/services/purchase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize core services
  final prefs = await SharedPreferences.getInstance();

  // App Tracking Transparency: Apple requires the tracking prompt (and the
  // user's authorization) BEFORE any ad SDK accesses the IDFA. Request it up
  // front so AdMob personalization is permitted when the user allows it.
  // On non-iOS platforms this is a no-op.
  try {
    if (await AppTrackingTransparency.trackingAuthorizationStatus ==
        TrackingStatus.notDetermined) {
      // Small delay lets the iOS privacy window settle before the dialog.
      await Future.delayed(const Duration(milliseconds: 200));
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  } catch (_) {
    // If ATT is unavailable (older iOS / non-iOS), continue without it.
  }

  // Initialize Ads (can run asynchronously) — must come AFTER ATT on iOS.
  MobileAds.instance.initialize();

  // Initialize Purchases
  await PurchaseService.init();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const DollarsToYuanApp(),
    ),
  );
}
