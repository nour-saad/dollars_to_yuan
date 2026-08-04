import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class ExchangeRateState {
  final double rate;
  final DateTime? lastUpdated;
  final bool isLoading;
  final String? error;
  final bool isOffline;

  ExchangeRateState({
    required this.rate,
    this.lastUpdated,
    this.isLoading = false,
    this.error,
    this.isOffline = false,
  });

  ExchangeRateState copyWith({
    double? rate,
    DateTime? lastUpdated,
    bool? isLoading,
    String? error,
    bool? isOffline,
  }) {
    return ExchangeRateState(
      rate: rate ?? this.rate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}

class ExchangeRateNotifier extends StateNotifier<ExchangeRateState> {
  final ApiService _apiService;
  final StorageService _storageService;

  // Default fallback rate if absolutely nothing is cached or fetching fails
  static const double _defaultRate = 7.15;

  ExchangeRateNotifier(this._apiService, this._storageService)
      : super(ExchangeRateState(
          rate: _storageService.getCachedRate() ?? _defaultRate,
          lastUpdated: _storageService.getCachedTimestamp(),
        )) {
    refreshRate();
  }

  Future<void> refreshRate() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final newRate = await _apiService.fetchUsdToCnyRate();
      final now = DateTime.now();
      
      // Cache the new rate
      await _storageService.cacheExchangeRate(newRate, now.millisecondsSinceEpoch);
      
      state = state.copyWith(
        rate: newRate,
        lastUpdated: now,
        isLoading: false,
        isOffline: false,
      );
    } catch (e) {
      // Fallback to cache if available
      final cachedRate = _storageService.getCachedRate();
      final cachedTime = _storageService.getCachedTimestamp();
      
      state = state.copyWith(
        rate: cachedRate ?? state.rate,
        lastUpdated: cachedTime ?? state.lastUpdated,
        isLoading: false,
        isOffline: true,
        error: e.toString(),
      );
    }
  }

  String getFormattedLastUpdated() {
    if (state.lastUpdated == null) return 'Never';
    
    final now = DateTime.now();
    final difference = now.difference(state.lastUpdated!);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    }
    
    // Absolute time
    return DateFormat.yMMMd().add_jm().format(state.lastUpdated!);
  }
}

final exchangeRateProvider = StateNotifierProvider<ExchangeRateNotifier, ExchangeRateState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  return ExchangeRateNotifier(apiService, storageService);
});
