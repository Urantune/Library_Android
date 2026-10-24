class AuthorResponse {
  final String name;
  final String? bio;
  final DateTime? birthDate;
  final String? country;
  final String status;
  final DateTime? createAt;
  final DateTime? updateAt;

  AuthorResponse({
    required this.name,
    this.bio,
    this.birthDate,
    this.country,
    required this.status,
    this.createAt,
    this.updateAt,
  });

  factory AuthorResponse.fromJson(Map<String, dynamic> json) {
    return AuthorResponse(
      name: json['name'] ?? '',
      bio: json['bio'],
      birthDate: json['birthDate'] != null ? DateTime.tryParse(json['birthDate']) : null,
      country: json['country'],
      status: json['status'] ?? '',
      createAt: json['create_at'] != null ? DateTime.tryParse(json['create_at']) : null,
      updateAt: json['update_at'] != null ? DateTime.tryParse(json['update_at']) : null,
    );
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

  PageDTO({
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
    return PageDTO(
      size: json['size'] ?? 0,
      page: json['page'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      totalElements: json['totalElements'] ?? 0,
      first: json['first'] ?? false,
      last: json['last'] ?? false,
      content: (json['content'] as List?)?.map((e) => fromJsonT(e)).toList() ?? [],
    );
  }
}
