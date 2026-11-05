class LoanResponseDTO {
  final String id;
  final String userId;
  final String status;
  final DateTime? requestedAt;
  final DateTime? approvedAt;
  final DateTime? borrowedAt;
  final DateTime? dueAt;
  final DateTime? returnedAt;
  final String? rejectionReason;
  final int renewCount;
  final List<Map<String, dynamic>> items;

  const LoanResponseDTO({
    required this.id,
    required this.userId,
    required this.status,
    this.requestedAt,
    this.approvedAt,
    this.borrowedAt,
    this.dueAt,
    this.returnedAt,
    this.rejectionReason,
    required this.renewCount,
    required this.items,
  });

  factory LoanResponseDTO.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return LoanResponseDTO(
      id: (json['id'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      requestedAt: _parseDate(json['requestedAt']),
      approvedAt: _parseDate(json['approvedAt']),
      borrowedAt: _parseDate(json['borrowedAt']),
      dueAt: _parseDate(json['dueAt']),
      returnedAt: _parseDate(json['returnedAt']),
      rejectionReason: json['rejectionReason']?.toString(),
      renewCount: (json['renewCount'] as num?)?.toInt() ?? 0,
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
          : const [],
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    return DateTime.tryParse(value.toString());
  }
}

class PageDTO<T> {
  final int size;
  final int page;
  final int totalPages;
  final int totalElements;
  final bool first;
  final bool last;
  final List<T> content;

  const PageDTO({
    required this.size,
    required this.page,
    required this.totalPages,
    required this.totalElements,
    required this.first,
    required this.last,
    required this.content,
  });

  factory PageDTO.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    return PageDTO<T>(
      size: (json['size'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
      first: json['first'] as bool? ?? false,
      last: json['last'] as bool? ?? false,
      content: (json['content'] as List? ?? [])
          .map((item) => fromJsonT(item))
          .toList(),
    );
  }
}