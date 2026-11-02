// PRM-023: Xem danh sách và chi tiết nhà xuất bản
// =====================================================

// Class Publisher đại diện cho một nhà xuất bản.
// Mỗi đối tượng Publisher tương ứng với một nhà xuất bản
// được lấy từ dữ liệu Backend.
class Publisher {
  // ID của nhà xuất bản.
  // Dùng để phân biệt các nhà xuất bản và lấy chi tiết.
  final int id;

  // Tên nhà xuất bản.
  final String name;

  // Địa chỉ của nhà xuất bản.
  final String address;

  // Số điện thoại liên hệ.
  final String phone;

  // Email liên hệ.
  final String email;

  // ===================================================
  // CONSTRUCTOR
  // ===================================================
  // Constructor dùng để tạo một đối tượng Publisher.
  // required: Bắt buộc phải truyền giá trị cho các thuộc tính.
  // const: Cho phép tạo đối tượng hằng khi các giá trị
  // truyền vào đều là hằng.
  const Publisher({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
  });

  // ===================================================
  // CHUYỂN JSON THÀNH OBJECT PUBLISHER
  // ===================================================

  // Backend trả dữ liệu về dưới dạng JSON.
  // Factory constructor này có nhiệm vụ chuyển JSON
  // thành một đối tượng Publisher để Flutter sử dụng.
  //
  // Map<String, dynamic>:
  // - String: Tên thuộc tính JSON.
  // - dynamic: Giá trị có thể thuộc nhiều kiểu dữ liệu.
  factory Publisher.fromJson(Map<String, dynamic> json) {
    // Tạo và trả về một đối tượng Publisher mới.
    return Publisher(
      // Lấy ID từ JSON và chuyển thành kiểu int.
      // toString() giúp xử lý cả trường hợp ID được trả về
      // dưới dạng số hoặc chuỗi số.
      id: int.parse(json['id'].toString()),

      // Lấy tên nhà xuất bản.
      // Nếu Backend không trả về name hoặc giá trị null
      // thì mặc định sử dụng chuỗi rỗng.
      name: json['name']?.toString() ?? '',

      // Lấy địa chỉ nhà xuất bản.
      // Nếu không có dữ liệu thì trả về chuỗi rỗng.
      address: json['address']?.toString() ?? '',

      // Lấy số điện thoại.
      phone: json['phone']?.toString() ?? '',

      // Lấy email.
      email: json['email']?.toString() ?? '',
    );
  }
}
