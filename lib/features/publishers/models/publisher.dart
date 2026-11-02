class Publisher {
  final int id;
  final String name;
  final String address;
  final String phone;
  final String email;

  const Publisher({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
  });

  factory Publisher.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final parsedId =
        rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');

    if (parsedId == null) {
      throw const FormatException(
        'Dữ liệu nhà xuất bản không có ID hợp lệ.',
      );
    }

    return Publisher(
      id: parsedId,
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toWriteJson() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
    };
  }
}
