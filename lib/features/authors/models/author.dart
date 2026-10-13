
class Author {
  final String id;
  final String name;
  final String? bio;
  final DateTime? birthDate;
  final String? country;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
      birthDate: _parseDate(json['birth_date']),
      country: json['country']?.toString(),
      status: (json['status'] ?? 'INACTIVE').toString(),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}
