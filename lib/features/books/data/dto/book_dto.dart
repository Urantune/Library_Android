import '../../domain/entities/book.dart';

class BookDto {
  const BookDto(this.json);

  final Map<String, dynamic> json;

  Book toDomain() {
    String names(Object? value) {
      if (value is! List) return '';
      return value
          .whereType<Map>()
          .map((item) => item['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .join(', ');
    }

    int number(Object? value) => value is num ? value.toInt() : 0;
    final publisher = json['publisher'];
    return Book(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      author: names(json['authors']),
      category: names(json['categories']),
      publisher: publisher is Map ? publisher['name']?.toString() ?? '' : '',
      isbn: json['isbn']?.toString() ?? '',
      year: number(json['publicationYear']),
      quantity: number(json['totalCopies']),
      available: number(json['availableCopies']),
      description: json['description']?.toString() ?? '',
    );
  }
}
