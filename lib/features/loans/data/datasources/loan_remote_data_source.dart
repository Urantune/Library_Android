import 'package:dio/dio.dart';
import '../../../../core/config/api_config.dart';

import '../../../../core/network/api_client.dart';
import '../models/loan_renewal_response.dart';
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
      (json) =>
          LoanResponseDTO.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  Future<PageDTO<LoanResponseDTO>> getAllLoans({
    String? userRoles,
    int page = 0,
    int size = 20,
  }) async {
    final headers = <String, dynamic>{};
    if (userRoles != null && userRoles.isNotEmpty) {
      headers['X-User-Roles'] = userRoles;
    }
    final response = await _dio.get(
      '/api/loans/admin',
      queryParameters: {'page': page, 'size': size},
      options: Options(headers: headers.isNotEmpty ? headers : null),
    );
    final result = _extractResult(response.data);
    return PageDTO<LoanResponseDTO>.fromJson(
      result,
      (json) =>
          LoanResponseDTO.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  Future<LoanResponseDTO> requestLoan({
    required String userId,
    required List<Map<String, dynamic>> items,
    required DateTime dueAt,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.post(
      '/api/loans',
      data: {
        'userId': userId,
        'dueAt': _formatDate(dueAt),
        'items': items,
      },
      cancelToken: cancelToken,
      options: Options(headers: {'X-User-Id': userId}),
    );
    return LoanResponseDTO.fromJson(_extractResult(response.data));
  }

  Future<LoanRenewalResponseDTO> requestRenewal({
    required String userId,
    required String loanId,
    String? reason,
  }) async {
    final trimmedReason = reason?.trim();
    final response = await _dio.post(
      '/api/loan-renewals',
      data: {
        'loanId': loanId,
        if (trimmedReason != null && trimmedReason.isNotEmpty)
          'reason': trimmedReason,
      },
      options: Options(headers: {'X-User-Id': userId}),
    );
    return LoanRenewalResponseDTO.fromJson(_extractResult(response.data));
  }

  Future<List<LoanRenewalResponseDTO>> getRenewals() async {
    final response = await _dio.get('/api/loan-renewals');
    final result = _extractListResult(response.data);
    return result
        .map(
          (item) => LoanRenewalResponseDTO.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<LoanRenewalResponseDTO> approveRenewal({
    required String renewalId,
    required String adminUserId,
  }) async {
    final response = await _dio.post(
      '/api/loan-renewals/admin/${Uri.encodeComponent(renewalId)}/approve',
      options: Options(headers: {'X-User-Id': adminUserId}),
    );
    return LoanRenewalResponseDTO.fromJson(_extractResult(response.data));
  }

  Future<LoanResponseDTO> approveLoan({
    required String loanId,
    required String adminUserId,
    required String userRoles,
  }) async {
    final response = await _dio.post(
      '/api/loans/admin/${Uri.encodeComponent(loanId)}/approve',
      options: Options(
        headers: {
          'X-User-Id': adminUserId,
          'X-User-Roles': userRoles,
        },
      ),
    );
    return LoanResponseDTO.fromJson(_extractResult(response.data));
  }

  Future<LoanResponseDTO> rejectLoan({
    required String loanId,
    required String adminUserId,
    required String userRoles,
    String? reason,
  }) async {
    final data = reason != null && reason.trim().isNotEmpty
        ? {'reason': reason.trim()}
        : null;
    final response = await _dio.post(
      '/api/loans/admin/${Uri.encodeComponent(loanId)}/reject',
      data: data,
      options: Options(
        headers: {
          'X-User-Id': adminUserId,
          'X-User-Roles': userRoles,
        },
      ),
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

  List<dynamic> _extractListResult(dynamic body) {
    if (body is! Map) {
      throw const FormatException('Phản hồi API gia hạn không hợp lệ.');
    }
    final result = body['result'] ?? body['data'];
    if (result is! List) {
      throw const FormatException(
        'Danh sách yêu cầu gia hạn trong phản hồi không hợp lệ.',
      );
    }
    return result;
  }

  static String get _defaultBaseUrl {
    const configured = String.fromEnvironment('LOANS_API_BASE_URL');
    if (configured.isNotEmpty) return configured;
    return ApiConfig.baseUrl;
  }

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
