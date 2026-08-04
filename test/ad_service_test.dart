import 'dart:io';

import 'package:dollars_to_yuan/src/core/services/ad_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdCounter (interstitial trigger logic)', () {
    test('does not fire before threshold', () {
      final counter = AdCounter(threshold: 4);
      // conversions 1..3 should not trigger
      expect(counter.recordConversion(), isFalse); // 1
      expect(counter.recordConversion(), isFalse); // 2
      expect(counter.recordConversion(), isFalse); // 3
      expect(counter.count, 3);
    });

    test('fires exactly on the threshold', () {
      final counter = AdCounter(threshold: 4);
      for (var i = 0; i < 3; i++) {
        counter.recordConversion();
      }
      expect(counter.recordConversion(), isTrue); // 4th -> fire
      expect(counter.count, 4);
    });

    test('resets after firing so it fires again after threshold', () {
      final counter = AdCounter(threshold: 2);
      expect(counter.recordConversion(), isFalse); // 1
      expect(counter.recordConversion(), isTrue); // 2 -> fire
      counter.reset();
      expect(counter.count, 0);
      expect(counter.recordConversion(), isFalse); // 1 after reset
      expect(counter.recordConversion(), isTrue); // 2 -> fire again
    });

    test('threshold of 1 fires on first conversion', () {
      final counter = AdCounter(threshold: 1);
      expect(counter.recordConversion(), isTrue);
    });
  });

  group('shouldShowInterstitial (pure helper)', () {
    test('returns false below threshold and true at/above', () {
      expect(shouldShowInterstitial(0, 4), isFalse);
      expect(shouldShowInterstitial(3, 4), isFalse);
      expect(shouldShowInterstitial(4, 4), isTrue);
      expect(shouldShowInterstitial(5, 4), isTrue);
    });
  });

  group('AdService config', () {
    test('exposes a positive threshold and valid ad unit IDs', () {
      final service = AdService();
      expect(service.conversionsBetweenAds, greaterThan(0));
      // Non-empty strings that match the configured (real or test) IDs.
      expect(service.bannerAdUnitId, isNotEmpty);
      expect(service.interstitialAdUnitId, isNotEmpty);
      // Mirrors AdService's getter: Android -> test IDs; all other platforms
      // (iOS, and the Windows/Web test harness) -> configured real iOS IDs.
      if (Platform.isAndroid) {
        const testPrefix = 'ca-app-pub-3940256099942544/';
        expect(service.bannerAdUnitId, startsWith(testPrefix));
        expect(service.interstitialAdUnitId, startsWith(testPrefix));
      } else {
        expect(service.bannerAdUnitId,
            equals('ca-app-pub-5032421313412543/2259672689'));
        expect(service.interstitialAdUnitId,
            equals('ca-app-pub-5032421313412543/1889685753'));
      }
    });

    test('premium users never trigger an interstitial', () {
      final service = AdService();
      for (var i = 0; i < 10; i++) {
        service.showInterstitialIfAppropriate(isPremium: true);
      }
      // Counter stays at 0 because premium short-circuits.
      expect(service.conversionsSinceLastAd, 0);
    });

    test('free users accumulate conversions toward the threshold', () {
      final service = AdService();
      service.showInterstitialIfAppropriate(isPremium: false);
      service.showInterstitialIfAppropriate(isPremium: false);
      expect(service.conversionsSinceLastAd, 2);
    });
  });
}
