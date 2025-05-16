import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

final _log = Logger('ApiService');

class ApiService {
  final Dio _dio;
  final String baseUrl;

  ApiService({
    required String baseUrl,
    Dio? dio,
  })  : baseUrl = baseUrl,
        _dio = dio ?? Dio();

  Future<Map<String, dynamic>> get(String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      _log.info('GET $path with params: $queryParameters');
      final response = await _dio.get(
        '$baseUrl/$path',
        queryParameters: queryParameters,
      );
      
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      _log.severe('Error in GET request: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> post(String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      _log.info('POST $path with data: ${json.encode(data)}');
      final response = await _dio.post(
        '$baseUrl/$path',
        data: data,
        queryParameters: queryParameters,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Failed to create/update data: ${response.statusCode}');
      }
    } catch (e) {
      _log.severe('Error in POST request: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> put(String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      _log.info('PUT $path with data: ${json.encode(data)}');
      final response = await _dio.put(
        '$baseUrl/$path',
        data: data,
        queryParameters: queryParameters,
      );
      
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to update data: ${response.statusCode}');
      }
    } catch (e) {
      _log.severe('Error in PUT request: $e');
      rethrow;
    }
  }

  Future<void> delete(String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      _log.info('DELETE $path');
      final response = await _dio.delete(
        '$baseUrl/$path',
        queryParameters: queryParameters,
      );
      
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete data: ${response.statusCode}');
      }
    } catch (e) {
      _log.severe('Error in DELETE request: $e');
      rethrow;
    }
  }
}
