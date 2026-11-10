import '../entities/book.dart';
import '../repositories/book_repository.dart';

class BookSaveService {
  BookSaveService(this._repository);
  final BookRepository _repository;

  Future<void> save(Book book, {required bool isEditing}) async {
    final errors = _validate(book);
    if (errors.isNotEmpty) throw StateError(errors.values.first);
    if (isEditing) {
      await _repository.updateBook(book);
    } else {
      await _repository.createBook(book);
    }
  }

  Map<String, String> _validate(Book book) {
    final errors = <String, String>{};
    for (final entry in {
      'title': book.title,
      'author': book.author,
      'category': book.category,
      'publisher': book.publisher,
      'isbn': book.isbn,
    }.entries) {
      if (entry.value.trim().isEmpty) {
        errors[entry.key] = 'Vui lòng nhập đầy đủ thông tin sách.';
      }
    }
    if (book.year < 1 || book.year > DateTime.now().year + 1) {
      errors['year'] = 'Năm xuất bản không hợp lệ.';
    }
    if (book.quantity < 0) errors['quantity'] = 'Số lượng không được âm.';
    if (book.available < 0 || book.available > book.quantity) {
      errors['available'] = 'Số còn sẵn phải nằm trong tổng số lượng.';
    }
    return errors;
  }
}
