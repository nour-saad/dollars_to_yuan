import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:io';
import 'storage_service.dart';
import '../config/app_config.dart';

class PurchaseService {
  static Future<void> init() async {
    if (kIsWeb) return;

    try {
      await Purchases.setLogLevel(LogLevel.info);

      late PurchasesConfiguration configuration;
      if (Platform.isAndroid) {
        configuration = PurchasesConfiguration(AppConfig.revenueCatGoogleKey);
      } else if (Platform.isIOS) {
        configuration = PurchasesConfiguration(AppConfig.revenueCatAppleKey);
      } else {
        return;
      }

      // Skip if the key is still a placeholder.
      if (configuration.apiKey.startsWith('YOUR_KEY') ||
          configuration.apiKey.isEmpty) {
        debugPrint('RevenueCat key not configured. Skipping initialization.');
        return;
      }

      await Purchases.configure(configuration);
    } catch (e) {
      debugPrint('Failed to initialize RevenueCat: $e');
    }
  }

  Future<bool> checkPremiumStatus() async {
    try {
      if (kIsWeb) return false;
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo
              .entitlements.all[AppConfig.premiumEntitlementId]?.isActive ==
          true;
    } catch (e) {
      debugPrint('Failed to check premium status: $e');
      return false;
    }
  }

  /// Purchase a specific package (from the current offering).
  Future<bool> purchasePackage(Package package) async {
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      return customerInfo.customerInfo
              .entitlements.all[AppConfig.premiumEntitlementId]?.isActive ==
          true;
    } on PurchasesError catch (e) {
      // User cancellation is not a failure worth logging loudly.
      debugPrint('Purchase failed/cancelled: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Failed to purchase package: $e');
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      return customerInfo
              .entitlements.all[AppConfig.premiumEntitlementId]?.isActive ==
          true;
    } catch (e) {
      debugPrint('Failed to restore purchases: $e');
      return false;
    }
  }

  Future<List<Package>> getOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null &&
          offerings.current!.availablePackages.isNotEmpty) {
        return offerings.current!.availablePackages;
      }
      return [];
    } catch (e) {
      debugPrint('Failed to fetch offerings: $e');
      return [];
    }
  }
}

final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  return PurchaseService();
});

// A provider that manages the user's premium status state
final premiumStatusProvider =
    StateNotifierProvider<PremiumStatusNotifier, bool>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  final purchaseService = ref.watch(purchaseServiceProvider);
  return PremiumStatusNotifier(storageService, purchaseService);
});

class PremiumStatusNotifier extends StateNotifier<bool> {
  final StorageService _storageService;
  final PurchaseService _purchaseService;

  PremiumStatusNotifier(this._storageService, this._purchaseService)
      : super(_storageService.isPremium()) {
    _init();
  }

  Future<void> _init() async {
    // Check actual RevenueCat status on startup.
    final isPremium = await _purchaseService.checkPremiumStatus();
    if (isPremium != state) {
      state = isPremium;
      await _storageService.setPremium(isPremium);
    }
  }

  // For testing UI without actual purchases
  Future<void> togglePremiumTest() async {
    state = !state;
    await _storageService.setPremium(state);
  }
}
