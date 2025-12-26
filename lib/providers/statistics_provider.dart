import 'package:flutter/foundation.dart';
import '../core/services/api_service.dart';
import '../core/constants/api_constants.dart';
import '../models/statistics_model.dart';

class StatisticsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // State
  DashboardStats? _dashboardStats;
  DailyStatistics? _dailyStats;
  List<WaiterPerformance> _waiterPerformance = [];
  RevenueChart? _revenueChart;
  bool _isLoading = false;
  String? _error;

  // Getters
  DashboardStats? get dashboardStats => _dashboardStats;
  DailyStatistics? get dailyStats => _dailyStats;
  List<WaiterPerformance> get waiterPerformance => _waiterPerformance;
  RevenueChart? get revenueChart => _revenueChart;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error state
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Fetch dashboard statistics
  Future<void> fetchDashboardStats() async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.get('${ApiConstants.statistics}/dashboard');

      if (response is Map<String, dynamic>) {
        _dashboardStats = DashboardStats.fromJson(response);
      }

      _setLoading(false);
    } catch (e) {
      _setError('Greška pri učitavanju statistike: ${e.toString()}');
      _setLoading(false);
      debugPrint('Error fetching dashboard stats: $e');
    }
  }

  // Fetch daily statistics
  Future<void> fetchDailyStats({DateTime? date}) async {
    _setLoading(true);
    _setError(null);

    try {
      final selectedDate = date ?? DateTime.now();
      final dateString = selectedDate.toIso8601String().split('T')[0];
      
      final response = await _apiService.get(
        '${ApiConstants.statistics}/daily?date=$dateString',
      );

      if (response is Map<String, dynamic>) {
        _dailyStats = DailyStatistics.fromJson(response);
      }

      _setLoading(false);
    } catch (e) {
      _setError('Greška pri učitavanju dnevne statistike: ${e.toString()}');
      _setLoading(false);
      debugPrint('Error fetching daily stats: $e');
    }
  }

  // Fetch waiter performance
  Future<void> fetchWaiterPerformance({int days = 30}) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.get(
        '${ApiConstants.statistics}/waiter-performance?days=$days',
      );

      if (response is List) {
        _waiterPerformance = response
            .map((json) => WaiterPerformance.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        _waiterPerformance = [];
      }

      _setLoading(false);
    } catch (e) {
      _setError('Greška pri učitavanju performanse: ${e.toString()}');
      _setLoading(false);
      debugPrint('Error fetching waiter performance: $e');
    }
  }

  // Fetch revenue chart data
  Future<void> fetchRevenueChart({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final fromString = fromDate.toIso8601String().split('T')[0];
      final toString = toDate.toIso8601String().split('T')[0];
      
      final response = await _apiService.get(
        '${ApiConstants.statistics}/revenue-chart?fromDate=$fromString&toDate=$toString',
      );

      if (response is Map<String, dynamic>) {
        _revenueChart = RevenueChart.fromJson(response);
      }

      _setLoading(false);
    } catch (e) {
      _setError('Greška pri učitavanju grafikona: ${e.toString()}');
      _setLoading(false);
      debugPrint('Error fetching revenue chart: $e');
    }
  }

  // Reset provider state
  void reset() {
    _dashboardStats = null;
    _dailyStats = null;
    _waiterPerformance = [];
    _revenueChart = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}

// Additional models for daily statistics and revenue chart

class DailyStatistics {
  final DateTime date;
  final double totalRevenue;
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final double averageOrderValue;
  final List<TopProduct> topProducts;
  final List<CategorySales> categorySales;

  const DailyStatistics({
    required this.date,
    required this.totalRevenue,
    required this.totalOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.averageOrderValue,
    this.topProducts = const [],
    this.categorySales = const [],
  });

  factory DailyStatistics.fromJson(Map<String, dynamic> json) {
    return DailyStatistics(
      date: DateTime.parse(json['date'] as String),
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      totalOrders: json['totalOrders'] as int,
      completedOrders: json['completedOrders'] as int,
      cancelledOrders: json['cancelledOrders'] as int,
      averageOrderValue: (json['averageOrderValue'] as num).toDouble(),
      topProducts: (json['topProducts'] as List?)
              ?.map((e) => TopProduct.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      categorySales: (json['categorySales'] as List?)
              ?.map((e) => CategorySales.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class CategorySales {
  final String categoryId;
  final String categoryName;
  final double revenue;
  final int orderCount;

  const CategorySales({
    required this.categoryId,
    required this.categoryName,
    required this.revenue,
    required this.orderCount,
  });

  factory CategorySales.fromJson(Map<String, dynamic> json) {
    return CategorySales(
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      revenue: (json['revenue'] as num).toDouble(),
      orderCount: json['orderCount'] as int,
    );
  }
}

class RevenueChart {
  final List<RevenueDataPoint> data;

  const RevenueChart({required this.data});

  factory RevenueChart.fromJson(Map<String, dynamic> json) {
    return RevenueChart(
      data: (json['data'] as List?)
              ?.map((e) => RevenueDataPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class RevenueDataPoint {
  final DateTime date;
  final double revenue;
  final int orderCount;

  const RevenueDataPoint({
    required this.date,
    required this.revenue,
    required this.orderCount,
  });

  factory RevenueDataPoint.fromJson(Map<String, dynamic> json) {
    return RevenueDataPoint(
      date: DateTime.parse(json['date'] as String),
      revenue: (json['revenue'] as num).toDouble(),
      orderCount: json['orderCount'] as int,
    );
  }
}