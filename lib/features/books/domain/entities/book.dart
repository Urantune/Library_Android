class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.publisher,
    required this.isbn,
    required this.year,
    required this.quantity,
    required this.available,
    this.description = '',
  });

  final String id;
  final String title;
  final String author;
  final String category;
  final String publisher;
  final String isbn;
  final int year;
  final int quantity;
  final int available;
  final String description;

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        id: '${json['id'] ?? ''}',
        title: '${json['title'] ?? ''}',
        author: '${json['author'] ?? ''}',
        category: '${json['category'] ?? ''}',
        publisher: '${json['publisher'] ?? ''}',
        isbn: '${json['isbn'] ?? ''}',
        year: (json['year'] as num?)?.toInt() ?? 0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        available: (json['available'] as num?)?.toInt() ?? 0,
        description: '${json['description'] ?? ''}',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'category': category,
        'publisher': publisher,
        'isbn': isbn,
        'year': year,
        'quantity': quantity,
        'available': available,
        'description': description,
      };

  Book copyWith({
    String? title,
    String? author,
    String? category,
    String? publisher,
    String? isbn,
    int? year,
    int? quantity,
    int? available,
    String? description,
  }) => Book(
        id: id,
        title: title ?? this.title,
        author: author ?? this.author,
        category: category ?? this.category,
        publisher: publisher ?? this.publisher,
        isbn: isbn ?? this.isbn,
        year: year ?? this.year,
        quantity: quantity ?? this.quantity,
        available: available ?? this.available,
        description: description ?? this.description,
      );
}
