import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../models/loan_response.dart';

class LoanRemoteDataSource {
  LoanRemoteDataSource({Dio? dio, String? baseUrl})
      : baseUrl = baseUrl ?? _defaultBaseUrl,
        _dio = dio ?? ApiClient.create(baseUrl: baseUrl ?? _defaultBaseUrl);

  final Dio _dio;
  final String baseUrl;

  Future<PageDTO<LoanResponseDTO>> getBorrowedLoans(
    String userId, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _dio.get(
      '/api/loans/users/${Uri.encodeComponent(userId)}/borrowed',
      queryParameters: {'page': page, 'size': size},
      options: Options(headers: {'X-User-Id': userId}),
    );
    final result = _extractResult(response.data);
    return PageDTO<LoanResponseDTO>.fromJson(
      result,
      (json) => LoanResponseDTO.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  Future<LoanResponseDTO> requestLoan({
    required String userId,
    required List<Map<String, dynamic>> items,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.post(
      '/api/loans',
      data: {'userId': userId, 'items': items},
      cancelToken: cancelToken,
      options: Options(headers: {'X-User-Id': userId}),
    );
    return LoanResponseDTO.fromJson(_extractResult(response.data));
  }

  Map<String, dynamic> _extractResult(dynamic body) {
    if (body is! Map) {
      throw const FormatException('Phản hồi API loans không hợp lệ.');
    }
    final result = body['result'] ?? body['data'] ?? body;
    if (result is! Map) {
      throw const FormatException('Dữ liệu loan trong phản hồi không hợp lệ.');
    }
    return Map<String, dynamic>.from(result);
  }

  static String get _defaultBaseUrl {
    const configured = String.fromEnvironment('LOANS_API_BASE_URL');
    if (configured.isNotEmpty) return configured;
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8083'
        : 'http://localhost:8083';
  }
}