import 'package:flutter/foundation.dart';
import 'package:orders_mobile/core/services/api/misc_api_services.dart';
import 'package:orders_mobile/models/products/product_model.dart';

class RecommendationsProvider with ChangeNotifier {
  final RecommendationsApiService _apiService = RecommendationsApiService();

  List<ProductModel> _recommendedProducts = [];
  List<ProductModel> _popularProducts = [];
  List<ProductModel> _timeBasedProducts = [];
  bool _isLoading = false;
  String? _error;

  List<ProductModel> get recommendedProducts => _recommendedProducts;
  List<ProductModel> get popularProducts => _popularProducts;
  List<ProductModel> get timeBasedProducts => _timeBasedProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchRecommendedProducts({String? userId, int count = 5}) async {
    _setLoading(true);
    _clearError();
    try {
      final response = await _apiService.getRecommendedProducts(userId: userId, count: count);
      if (response.success && response.data != null) {
        _recommendedProducts = response.data!;
      } else {
        _setError(response.error ?? 'Failed to fetch recommendations');
      }
    } catch (e) {
      _setError('Error fetching recommendations: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchPopularProducts({int count = 10}) async {
    _setLoading(true);
    _clearError();
    try {
      final response = await _apiService.getPopularProducts(count: count);
      if (response.success && response.data != null) {
        _popularProducts = response.data!;
      } else {
        _setError(response.error ?? 'Failed to fetch popular products');
      }
    } catch (e) {
      _setError('Error fetching popular products: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchTimeBasedRecommendations({int? hour, int count = 5}) async {
    _setLoading(true);
    _clearError();
    final currentHour = hour ?? DateTime.now().hour;
    try {
      final response = await _apiService.getTimeBasedRecommendations(hour: currentHour, count: count);
      if (response.success && response.data != null) {
        _timeBasedProducts = response.data!;
      } else {
        _setError(response.error ?? 'Failed to fetch time-based recommendations');
      }
    } catch (e) {
      _setError('Error fetching time-based recommendations: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchAllRecommendations({
    String? userId,
    int recommendedCount = 5,
    int popularCount = 10,
    int timeBasedCount = 5,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      await Future.wait([
        fetchRecommendedProducts(userId: userId, count: recommendedCount),
        fetchPopularProducts(count: popularCount),
        fetchTimeBasedRecommendations(count: timeBasedCount),
      ]);
    } catch (e) {
      _setError('Error fetching recommendations: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    if (error != null) debugPrint('RecommendationsProvider error: $error');
    notifyListeners();
  }

  void _clearError() => _error = null;
}
