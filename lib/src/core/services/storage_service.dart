import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Will be overridden in main.dart
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static const String _rateKey = 'cached_exchange_rate';
  static const String _timestampKey = 'cached_timestamp';
  static const String _isPremiumKey = 'is_premium';

  Future<void> cacheExchangeRate(double rate, int timestampMillis) async {
    await _prefs.setDouble(_rateKey, rate);
    await _prefs.setInt(_timestampKey, timestampMillis);
  }

  double? getCachedRate() {
    return _prefs.getDouble(_rateKey);
  }

  DateTime? getCachedTimestamp() {
    final millis = _prefs.getInt(_timestampKey);
    if (millis != null) {
      return DateTime.fromMillisecondsSinceEpoch(millis);
    }
    return null;
  }
  
  Future<void> setPremium(bool isPremium) async {
    await _prefs.setBool(_isPremiumKey, isPremium);
  }
  
  bool isPremium() {
    return _prefs.getBool(_isPremiumKey) ?? false;
  }
}

final storageServiceProvider = Provider<StorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StorageService(prefs);
});
