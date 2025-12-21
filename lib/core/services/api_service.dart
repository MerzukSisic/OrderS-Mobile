import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _storage = const FlutterSecureStorage();
  String? _accessToken;

  // Get token
  Future<String?> getToken() async {
    _accessToken ??= await _storage.read(key: AppConstants.keyAccessToken);
    return _accessToken;
  }

  // Save token
  Future<void> saveToken(String token) async {
    _accessToken = token;
    await _storage.write(key: AppConstants.keyAccessToken, value: token);
  }

  // Clear token
  Future<void> clearToken() async {
    _accessToken = null;
    await _storage.delete(key: AppConstants.keyAccessToken);
  }

  // Get headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // GET Request
  Future<dynamic> get(String endpoint,
      {Map<String, String>? queryParams}) async {
    try {
      final uri = Uri.parse(ApiConstants.baseUrl + endpoint)
          .replace(queryParameters: queryParams);

      final response = await http
          .get(
            uri,
            headers: await _getHeaders(),
          )
          .timeout(ApiConstants.timeout);

      return _handleResponse(response);
    } on http.ClientException catch (e) {
      throw ApiException(
          'Connection error: ${e.message}. Please check your internet connection and server status.');
    } on Exception catch (e) {
      final errorMessage = e.toString();
      if (errorMessage.contains('TimeoutException') ||
          errorMessage.contains('timeout')) {
        throw ApiException(
            'Request timeout. The server is taking too long to respond. Please try again.');
      }
      throw ApiException('Network error: $errorMessage');
    } catch (e) {
      throw ApiException('Unexpected error: ${e.toString()}');
    }
  }

  // POST Request
  Future<dynamic> post(String endpoint, {dynamic body}) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConstants.baseUrl + endpoint),
            headers: await _getHeaders(),
            body: json.encode(body),
          )
          .timeout(ApiConstants.timeout);

      return _handleResponse(response);
    } on http.ClientException catch (e) {
      throw ApiException(
          'Connection error: ${e.message}. Please check your internet connection and server status.');
    } on Exception catch (e) {
      final errorMessage = e.toString();
      if (errorMessage.contains('TimeoutException') ||
          errorMessage.contains('timeout')) {
        throw ApiException(
            'Request timeout. The server is taking too long to respond. Please try again.');
      }
      throw ApiException('Network error: $errorMessage');
    } catch (e) {
      throw ApiException('Unexpected error: ${e.toString()}');
    }
  }

  // PUT Request
  Future<dynamic> put(String endpoint, {dynamic body}) async {
    try {
      final response = await http
          .put(
            Uri.parse(ApiConstants.baseUrl + endpoint),
            headers: await _getHeaders(),
            body: json.encode(body),
          )
          .timeout(ApiConstants.timeout);

      return _handleResponse(response);
    } on http.ClientException catch (e) {
      throw ApiException(
          'Connection error: ${e.message}. Please check your internet connection and server status.');
    } on Exception catch (e) {
      final errorMessage = e.toString();
      if (errorMessage.contains('TimeoutException') ||
          errorMessage.contains('timeout')) {
        throw ApiException(
            'Request timeout. The server is taking too long to respond. Please try again.');
      }
      throw ApiException('Network error: $errorMessage');
    } catch (e) {
      throw ApiException('Unexpected error: ${e.toString()}');
    }
  }

  // DELETE Request
  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await http
          .delete(
            Uri.parse(ApiConstants.baseUrl + endpoint),
            headers: await _getHeaders(),
          )
          .timeout(ApiConstants.timeout);

      return _handleResponse(response);
    } on http.ClientException catch (e) {
      throw ApiException(
          'Connection error: ${e.message}. Please check your internet connection and server status.');
    } on Exception catch (e) {
      final errorMessage = e.toString();
      if (errorMessage.contains('TimeoutException') ||
          errorMessage.contains('timeout')) {
        throw ApiException(
            'Request timeout. The server is taking too long to respond. Please try again.');
      }
      throw ApiException('Network error: $errorMessage');
    } catch (e) {
      throw ApiException('Unexpected error: ${e.toString()}');
    }
  }

  // Handle Response
  dynamic _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
      case 204:
        if (response.body.isEmpty) return null;
        return json.decode(response.body);
      case 400:
        throw ApiException('Bad request: ');
      case 401:
        throw UnauthorizedException('Unauthorized');
      case 404:
        throw ApiException('Not found');
      case 500:
        throw ApiException('Server error');
      default:
        throw ApiException('Error: ');
    }
  }
}

// Exceptions
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);

  @override
  String toString() => message;
}
