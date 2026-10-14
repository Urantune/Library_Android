// Model Publisher đại diện cho một Nhà xuất bản trong hệ thống.
// Class này dùng để:
// 1. Lưu dữ liệu của một nhà xuất bản.
// 2. Chuyển dữ liệu JSON từ API / file fake JSON thành object Publisher.
class Publisher {
  final int id;
  final String name;
  final String address;
  final String phone;
  final String email;
  final String description;

  // Constructor dùng để tạo một object Publisher.
  // const:
  // Cho phép tạo object dạng constant nếu toàn bộ dữ liệu truyền vào là constant.
  // required:
  // Bắt buộc phải truyền đầy đủ các thuộc tính khi tạo Publisher.
  const Publisher({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required this.description,
  });

  // Factory constructor dùng để chuyển dữ liệu JSON thành một object Publisher.
  // Khi đọc JSON từ:
  // - API backend
  // - file assets/data/publishers/duykhang.json
  // Hàm fromJson sẽ đọc từng field trong JSON
  // và gán vào thuộc tính tương ứng của Publisher.
  factory Publisher.fromJson(Map<String, dynamic> json) {
    return Publisher(
      // json['id'] có thể được trả về dưới dạng int hoặc String.
      // Vì vậy:
      // 1. json['id'].toString()
      //    -> chuyển giá trị thành String.
      // 2. int.tryParse(...)
      //    -> thử chuyển String thành int.
      // 3. ?? 0
      //    -> nếu chuyển thất bại thì dùng giá trị mặc định là 0.
      // Cách này giúp tránh app bị crash khi dữ liệu id không đúng kiểu.
      id: int.tryParse(json['id'].toString()) ?? 0,

      // ?.toString():
      // Nếu giá trị không null thì chuyển thành String.
      // ?? '':
      // Nếu dữ liệu bị null hoặc thiếu field thì dùng chuỗi rỗng.
      // Nhờ vậy app không bị lỗi null khi hiển thị dữ liệu.
      name: json['name']?.toString() ?? '',

      // Lấy địa chỉ từ JSON.
      // Nếu không có địa chỉ thì dùng chuỗi rỗng.
      address: json['address']?.toString() ?? '',

      // Lấy số điện thoại từ JSON.
      // Chuyển về String để giữ được các số 0 ở đầu.
      phone: json['phone']?.toString() ?? '',

      // Lấy email từ JSON.
      email: json['email']?.toString() ?? '',

      // Lấy phần mô tả từ JSON.
      description: json['description']?.toString() ?? '',
    );
  }
}
