import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiService {
  final Dio _dio;

  ApiService(this._dio);

  // Fetch exchange rate from Frankfurter API
  Future<double> fetchUsdToCnyRate() async {
    try {
      final response = await _dio.get(
        'https://api.frankfurter.app/latest',
        queryParameters: {
          'from': 'USD',
          'to': 'CNY',
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data['rates'] != null && data['rates']['CNY'] != null) {
          // ensure we return a double, as it could be parsed as int if it's a whole number
          return (data['rates']['CNY'] as num).toDouble();
        }
      }
      throw Exception('Invalid response format');
    } catch (e) {
      // In production, we'd log this or try a fallback API here
      throw Exception('Failed to fetch exchange rate: $e');
    }
  }
}

final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
});

final apiServiceProvider = Provider<ApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiService(dio);
});
