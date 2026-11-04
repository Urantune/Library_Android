enum CategoryStatus {
  active,
  inactive;

  static CategoryStatus fromJson(String? value) =>
      value?.toUpperCase() == 'INACTIVE'
          ? CategoryStatus.inactive
          : CategoryStatus.active;

  String toJson() => name.toUpperCase();
}

class BookCategory {
  final String id;
  final String name;
  final String description;
  final String? parentId;
  final CategoryStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BookCategory({
    required this.id,
    required this.name,
    this.description = '',
    this.parentId,
    this.status = CategoryStatus.active,
    this.createdAt,
    this.updatedAt,
  });

  factory BookCategory.fromJson(Map<String, dynamic> json) => BookCategory(
        id: json['id'].toString(),
        name: (json['name'] as String?) ?? '',
        description: (json['description'] as String?) ?? '',
        parentId: _nullIfEmpty(json['parentId']),
        status: CategoryStatus.fromJson(json['status'] as String?),
        createdAt: _parseDate(json['createdAt']),
        updatedAt: _parseDate(json['updatedAt']),
      );

  static String? _nullIfEmpty(Object? v) {
    final s = v?.toString();
    return (s == null || s.isEmpty) ? null : s;
  }

  static DateTime? _parseDate(Object? v) =>
      v is String ? DateTime.tryParse(v) : null;
}
