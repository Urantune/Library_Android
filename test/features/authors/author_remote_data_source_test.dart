import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lore_dungeo_library/features/authors/data/datasources/author_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

Response<dynamic> _response(String path, {dynamic data, int statusCode = 200}) {
  return Response<dynamic>(
    requestOptions: RequestOptions(path: path),
    data: data,
    statusCode: statusCode,
  );
}

void main() {
  late _MockDio dio;
  late AuthorRemoteDataSource dataSource;

  setUp(() {
    dio = _MockDio();
    dataSource = AuthorRemoteDataSource(
      dio: dio,
      baseUrl: 'http://localhost:8082',
    );
  });

  test('fetches and parses a page of authors from the API response', () async {
    when(() => dio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => _response(
          '/api/authors',
          data: {
            'result': {
              'size': 10,
              'page': 1,
              'totalPages': 3,
              'totalElements': 21,
              'first': false,
              'last': false,
              'content': [
                {
                  'id': 'author-1',
                  'name': 'Author One',
                  'bio': 'Bio',
                  'birthDate': '1980-02-03',
                  'country': 'VN',
                  'status': 'ACTIVE',
                },
              ],
            },
          },
        ));

    final page = await dataSource.fetchAuthors(page: 1, size: 10);

    expect(page.totalElements, 21);
    expect(page.content.single.id, 'author-1');
    expect(page.content.single.birthDate, DateTime(1980, 2, 3));
    verify(() => dio.get<dynamic>(
          'http://localhost:8082/api/authors',
          queryParameters: {'page': 1, 'size': 10},
        )).called(1);
  });

  test('sends the create request with LocalDate formatted as yyyy-MM-dd',
      () async {
    when(() => dio.post<dynamic>(
          any(),
          data: any(named: 'data'),
        )).thenAnswer((_) async => _response('/api/authors', statusCode: 201));

    await dataSource.createAuthor(
      name: 'New Author',
      bio: 'Bio',
      birthDate: DateTime(1990, 4, 5),
      country: 'VN',
      status: 'ACTIVE',
    );

    verify(() => dio.post<dynamic>(
          'http://localhost:8082/api/authors',
          data: {
            'name': 'New Author',
            'bio': 'Bio',
            'birthDate': '1990-04-05',
            'country': 'VN',
            'status': 'ACTIVE',
          },
        )).called(1);
  });

  test('sends the update request to the author ID endpoint', () async {
    when(() => dio.put<dynamic>(
          any(),
          data: any(named: 'data'),
        )).thenAnswer((_) async => _response('/api/authors/author-1'));

    await dataSource.updateAuthor(
      id: 'author-1',
      name: 'Updated Author',
      birthDate: DateTime(1985, 6, 7),
      status: 'INACTIVE',
    );

    verify(() => dio.put<dynamic>(
          'http://localhost:8082/api/authors/author-1',
          data: {
            'name': 'Updated Author',
            'bio': null,
            'birthDate': '1985-06-07',
            'country': null,
            'status': 'INACTIVE',
          },
        )).called(1);
  });

  test('sends the delete request to the encoded author ID endpoint', () async {
    when(() => dio.delete<dynamic>(any()))
        .thenAnswer((_) async => _response('/api/authors/author%201'));

    await dataSource.deleteAuthor('author 1');

    verify(() => dio.delete<dynamic>(
          'http://localhost:8082/api/authors/author%201',
        )).called(1);
  });
}