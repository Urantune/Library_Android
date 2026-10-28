class Author {
  final String id;
  final String name;
  final String? bio;
  final DateTime? birthDate;
  final String? country;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

// const -> final
  const Author({
    required this.id,
    required this.name,
    this.bio,
    this.birthDate,
    this.country,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      bio: json['bio']?.toString(),
      birthDate: _parseDate(
        json['birthDate'] ?? json['birth_date'],
      ),
      country: json['country']?.toString(),
      status: (json['status'] ?? 'INACTIVE').toString(),
      createdAt: _parseDate(
        json['createdAt'] ?? json['created_at'],
      ),
      updatedAt: _parseDate(
        json['updatedAt'] ?? json['updated_at'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'birthDate': _formatDate(birthDate),
      'country': country,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }

  static String? _formatDate(DateTime? date) {
    if (date == null) return null;

    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
