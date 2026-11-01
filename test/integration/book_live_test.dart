import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lore_dungeo_library/core/network/api_client.dart';
import 'package:lore_dungeo_library/features/books/data/datasources/book_remote_data_source.dart';

void main() {
  test('Gateway HTTP loads book list and matching detail from Catalog',
      () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({});
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final original = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = original);
    final dio = ApiClient.create();
    addTearDown(() => dio.close());
    final remote = BookRemoteDataSource(dio);
    final books = await remote.getBooks();
    expect(books, isNotEmpty);
    final first = books.first;
    final detail = await remote.getBookById(first.id);
    expect(detail.id, first.id);
    expect(detail.title, first.title);
    expect(detail.isbn, first.isbn);
  }, skip: !const bool.fromEnvironment('RUN_LIVE_BOOKS'));
}
