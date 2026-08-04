import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';
import 'storage_service.dart';
import '../config/app_config.dart';

/// Pure, testable threshold check: should an interstitial fire now?
bool shouldShowInterstitial(int conversionsSinceLastAd, int threshold) =>
    conversionsSinceLastAd >= threshold;

/// Tracks how many conversions have happened since the last ad was shown.
/// Pure logic, no AdMob dependency — safe to unit test in any environment.
class AdCounter {
  final int threshold;
  int _count = 0;

  AdCounter({this.threshold = 4});

  /// Record a conversion. Returns true once the threshold is reached.
  bool recordConversion() {
    _count++;
    return shouldShowInterstitial(_count, threshold);
  }

  void reset() => _count = 0;
  int get count => _count;
}

class AdService {
  InterstitialAd? _interstitialAd;
  final AdCounter _counter = AdCounter(threshold: 4);
  bool _isInterstitialLoading = false;

  // Ad Unit IDs — sourced from AppConfig (real iOS IDs, test Android IDs pending).
  String get bannerAdUnitId {
    return Platform.isAndroid
        ? AppConfig.androidBannerAdUnitId
        : AppConfig.iosBannerAdUnitId;
  }

  String get interstitialAdUnitId {
    return Platform.isAndroid
        ? AppConfig.androidInterstitialAdUnitId
        : AppConfig.iosInterstitialAdUnitId;
  }

  void loadInterstitialAd() {
    if (_isInterstitialLoading || _interstitialAd != null) return;

    _isInterstitialLoading = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
        },
        onAdFailedToLoad: (error) {
          _isInterstitialLoading = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  /// Increment the conversion counter and show an interstitial if the user is
  /// due one. Premium users are always exempt ([isPremium] = true).
  void showInterstitialIfAppropriate({bool isPremium = false}) {
    if (isPremium) return; // Premium users never see interstitials.

    if (_counter.recordConversion()) {
      if (_interstitialAd != null) {
        _interstitialAd!.show();
        _interstitialAd = null;
        _counter.reset();
        // Pre-load the next one
        loadInterstitialAd();
      } else {
        // Ad wasn't ready — try to load one for next time.
        loadInterstitialAd();
      }
    }
  }

  // --- Test / inspection helpers (no AdMob SDK calls) ---
  int get conversionsSinceLastAd => _counter.count;
  int get conversionsBetweenAds => _counter.threshold;
}

final adServiceProvider = Provider<AdService>((ref) {
  final service = AdService();
  // Don't waste bandwidth preloading ads for premium users.
  final storage = ref.watch(storageServiceProvider);
  if (!storage.isPremium()) service.loadInterstitialAd();
  return service;
});
