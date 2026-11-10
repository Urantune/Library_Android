class BookCopy {
  const BookCopy({required this.id, required this.code, required this.status,
    required this.condition, this.shelfLocation});

  final String id;
  final String code;
  final String status;
  final String condition;
  final String? shelfLocation;

  factory BookCopy.fromJson(Map<String, dynamic> json) => BookCopy(
    id: json['id']?.toString() ?? '',
    code: json['code']?.toString() ?? '',
    status: json['status']?.toString() ?? '',
    condition: json['condition']?.toString() ?? '',
    shelfLocation: json['shelfLocation']?.toString(),
  );
}
