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
    this.language = '',
    this.coverUrl = '',
    this.pageCount,
    this.status = 'ACTIVE',
    this.publisherId,
    this.authorIds = const [],
    this.categoryIds = const [],
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
  final String language;
  final String coverUrl;
  final int? pageCount;
  final String status;
  final String? publisherId;
  final List<String> authorIds;
  final List<String> categoryIds;

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
        language: '${json['language'] ?? ''}',
        coverUrl: '${json['coverUrl'] ?? ''}',
        pageCount: (json['pageCount'] as num?)?.toInt(),
        status: '${json['status'] ?? 'ACTIVE'}',
        publisherId: json['publisherId']?.toString(),
        authorIds: (json['authorIds'] is List)
            ? (json['authorIds'] as List).map((e) => e.toString()).toList()
            : const [],
        categoryIds: (json['categoryIds'] is List)
            ? (json['categoryIds'] as List).map((e) => e.toString()).toList()
            : const [],
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
        'language': language,
        'coverUrl': coverUrl,
        'pageCount': pageCount,
        'status': status,
        'publisherId': publisherId,
        'authorIds': authorIds,
        'categoryIds': categoryIds,
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
    String? language,
    String? coverUrl,
    int? pageCount,
    String? status,
    String? publisherId,
    List<String>? authorIds,
    List<String>? categoryIds,
  }) =>
      Book(
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
        language: language ?? this.language,
        coverUrl: coverUrl ?? this.coverUrl,
        pageCount: pageCount ?? this.pageCount,
        status: status ?? this.status,
        publisherId: publisherId ?? this.publisherId,
        authorIds: authorIds ?? this.authorIds,
        categoryIds: categoryIds ?? this.categoryIds,
      );
}
