
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// import '../../../core/api_client.dart';
// import '../models/author.dart';
// import '../services/author_service.dart';

// final authorServiceProvider = Provider<AuthorService>((ref) {
//   return AuthorService(ApiClient.dio);
// });

// final authorListProvider = FutureProvider<List<Author>>((ref) {
//   return ref.watch(authorServiceProvider).getAuthors();
// });

// final authorDetailProvider =
//     FutureProvider.family<Author, String>((ref, id) {
//   return ref.watch(authorServiceProvider).getAuthorById(id);
// });


import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/author.dart';
import '../services/author_service.dart';

/// true  = dùng dữ liệu mẫu, chưa cần BE.
/// false = gọi API Spring Boot.
const bool useMockAuthors = true;

final authorServiceProvider = Provider<AuthorService>((ref) {
  return AuthorService();
});

final mockAuthorsProvider = Provider<List<Author>>((ref) {
  return [
    Author(
      id: 'author-001',
      name: 'Nguyễn Nhật Ánh',
      bio: 'Nhà văn Việt Nam nổi tiếng với nhiều tác phẩm dành cho thiếu nhi và tuổi mới lớn.',
      birthDate: DateTime(1955, 5, 7),
      country: 'Việt Nam',
      status: 'ACTIVE',
      createdAt: DateTime(2026, 9, 1, 8, 30),
      updatedAt: DateTime(2026, 10, 1, 10, 15),
    ),
    Author(
      id: 'author-002',
      name: 'Tô Hoài',
      bio: 'Nhà văn Việt Nam, được biết đến với tác phẩm Dế Mèn phiêu lưu ký.',
      birthDate: DateTime(1920, 9, 27),
      country: 'Việt Nam',
      status: 'ACTIVE',
      createdAt: DateTime(2026, 9, 5, 9, 0),
      updatedAt: DateTime(2026, 9, 20, 14, 30),
    ),
    Author(
      id: 'author-003',
      name: 'J. K. Rowling',
      bio: 'Nhà văn người Anh, nổi tiếng với bộ truyện Harry Potter.',
      birthDate: DateTime(1965, 7, 31),
      country: 'Vương quốc Anh',
      status: 'ACTIVE',
      createdAt: DateTime(2026, 9, 10, 10, 0),
      updatedAt: DateTime(2026, 10, 2, 16, 0),
    ),
    Author(
      id: 'author-004',
      name: 'Tác giả chưa cập nhật',
      bio: null,
      birthDate: null,
      country: null,
      status: 'INACTIVE',
      createdAt: DateTime(2026, 8, 1, 12, 0),
      updatedAt: null,
    ),
  ];
});

final authorListProvider = FutureProvider<List<Author>>((ref) async {
  if (useMockAuthors) {
    await Future<void>.delayed(
      const Duration(milliseconds: 300),
    );

    return ref.watch(mockAuthorsProvider);
  }

  return ref.watch(authorServiceProvider).getAuthors();
});

final authorDetailProvider =
    FutureProvider.family<Author, String>((ref, authorId) async {
  if (useMockAuthors) {
    await Future<void>.delayed(
      const Duration(milliseconds: 200),
    );

    final authors = ref.watch(mockAuthorsProvider);

    return authors.firstWhere(
      (author) => author.id == authorId,
      orElse: () => throw Exception('Không tìm thấy tác giả.'),
    );
  }

  return ref.watch(authorServiceProvider).getAuthorById(authorId);
});

