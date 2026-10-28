class User {
  const User(
      {required this.id,
      required this.fullName,
      required this.email,
      this.roles = const ['MEMBER'],
      this.status = 'ACTIVE'});
  final String id;
  final String fullName;
  final String email;
  final List<String> roles;
  final String status;

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        email: json['email'] as String,
        roles: List<String>.from(json['roles'] as List? ?? const ['MEMBER']),
        status: json['status'] as String? ?? 'ACTIVE',
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'roles': roles,
        'status': status,
      };
}
