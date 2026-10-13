// ───────────────────────── Model ─────────────────────────
class BookCategory {
  final int id;
  final String name;
  final String description;
  final int bookCount;

  const BookCategory({
    required this.id,
    required this.name,
    required this.description,
    this.bookCount = 0,
  });

  factory BookCategory.fromJson(Map<String, dynamic> json) => BookCategory(
        id: (json['id'] as num).toInt(),
        name: (json['name'] as String?) ?? '',
        description: (json['description'] as String?) ?? '',
        bookCount: (json['bookCount'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'bookCount': bookCount,
      };

  BookCategory copyWith({String? name, String? description}) => BookCategory(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        bookCount: bookCount,
      );
}
