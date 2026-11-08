import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../books/domain/entities/book.dart';
import '../../data/models/loan_response.dart';
import '../providers/loan_provider.dart';

class BorrowedLoansScreen extends ConsumerStatefulWidget {
  const BorrowedLoansScreen({super.key});

  @override
  ConsumerState<BorrowedLoansScreen> createState() =>
      _BorrowedLoansScreenState();
}

class _BorrowedLoansScreenState extends ConsumerState<BorrowedLoansScreen> {
  String _query = '';
  bool _isRequestingLoan = false;

  @override
  Widget build(BuildContext context) {
    final userIdAsync = ref.watch(loanCurrentUserIdProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text(
          'Mượn - Trả',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Làm mới',
              onPressed: () => ref.invalidate(loanCurrentUserIdProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: userIdAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _ErrorView(
          message: 'Không thể xác định người dùng: $error',
          onRetry: () => ref.invalidate(loanCurrentUserIdProvider),
        ),
        data: (userId) => ref.watch(borrowedLoansProvider(userId)).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _ErrorView(
            message: _loanRequestErrorMessage(
              error,
              action: 'tải danh sách mượn',
            ),
            onRetry: () => ref.invalidate(borrowedLoansProvider(userId)),
          ),
          data: (page) => _buildLoanList(userId, page),
        ),
      ),
    );
  }

  Widget _buildLoanList(String userId, PageDTO<LoanResponseDTO> page) {
    final loans = page.content.where((loan) {
      final searchable =
          '${loan.id} ${loan.status} ${loan.items}'.toLowerCase();
      return searchable.contains(_query);
    }).toList()
      ..sort((a, b) =>
          (b.requestedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(a.requestedAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
    final borrowedLoans = loans
        .where((loan) => loan.status.toUpperCase() == 'BORROWED')
        .toList();
    final borrowedBookCount = borrowedLoans.fold<int>(
      0,
      (count, loan) => count + loan.items.length,
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(borrowedLoansProvider(userId));
        await ref.read(borrowedLoansProvider(userId).future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          TextField(
            onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Tìm theo mã phiếu hoặc trạng thái...',
              prefixIcon: const Icon(Icons.search, size: 19),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFE1E6ED)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFE1E6ED)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isRequestingLoan ? null : () => _requestLoan(userId),
              icon: _isRequestingLoan
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: Text(
                _isRequestingLoan ? 'Đang gửi yêu cầu...' : 'Yêu cầu mượn sách',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${page.totalElements} phiếu mượn',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF667085),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Sách đang mượn ($borrowedBookCount)',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF25364A),
            ),
          ),
          const SizedBox(height: 8),
          if (borrowedBookCount == 0)
            const Text(
              'Chưa có sách ở trạng thái BORROWED.',
              style: TextStyle(fontSize: 12, color: Color(0xFF667085)),
            )
          else
            for (final loan in borrowedLoans)
              for (var index = 0; index < loan.items.length; index++)
                _BorrowedBookTile(
                  item: loan.items[index],
                  index: index,
                  loanId: loan.id,
                  dueAt: loan.dueAt,
                ),
          const SizedBox(height: 18),
          const Text(
            'Phiếu mượn',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF25364A),
            ),
          ),
          const SizedBox(height: 8),
          if (loans.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: Text('Không có phiếu mượn phù hợp.')),
            )
          else
            for (final loan in loans) ...[
              _LoanCard(loan: loan),
              const SizedBox(height: 9),
            ],
        ],
      ),
    );
  }

  Future<void> _requestLoan(String userId) async {
    var action = 'tải danh sách sách';
    setState(() => _isRequestingLoan = true);
    try {
      final books = await ref.read(loanBookListProvider.future).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException(
          'API sách không phản hồi tại port 8082.',
        ),
      );
      if (books.isEmpty) {
        throw StateError('API sách không trả về danh sách sách.');
      }
      if (!mounted) return;

      final selectedBooks = <Book>{};
      final selection = await showDialog<List<Book>>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Chọn sách muốn mượn'),
            content: SizedBox(
              width: 440,
              height: 320,
              child: ListView.builder(
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final book = books[index];
                  final isActive = book.status.toUpperCase() == 'ACTIVE';
                  return CheckboxListTile(
                    value: selectedBooks.contains(book),
                    title: Text(book.title),
                    subtitle: Text(
                      '${book.status} · Còn ${book.available} bản',
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    onChanged: isActive
                        ? (selected) {
                            setDialogState(() {
                              if (selected == true) {
                                selectedBooks.add(book);
                              } else {
                                selectedBooks.remove(book);
                              }
                            });
                          }
                        : null,
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: selectedBooks.isEmpty
                    ? null
                    : () => Navigator.of(dialogContext)
                        .pop(selectedBooks.toList()),
                child: const Text('Gửi yêu cầu'),
              ),
            ],
          ),
        ),
      );

      if (selection == null || selection.isEmpty || !mounted) return;

      action = 'gửi yêu cầu mượn';
      final cancelToken = CancelToken();
      final createdLoan = await ref.read(loanRemoteDataSourceProvider).requestLoan(
        userId: userId,
        items: selection.map((book) => {'bookId': book.id}).toList(),
        cancelToken: cancelToken,
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          cancelToken.cancel('Loan request timed out');
          throw TimeoutException('BE không phản hồi sau 20 giây.');
        },
      );
      ref.invalidate(borrowedLoansProvider(userId));
      if (mounted) {
        final returnedCount = createdLoan.items.length;
        final message = returnedCount == selection.length
            ? 'Đã gửi phiếu ${createdLoan.id} với $returnedCount đầu sách.'
            : 'BE tạo phiếu ${createdLoan.id} nhưng phản hồi '
                '$returnedCount/${selection.length} loan item. Kiểm tra service lưu chi tiết.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_loanRequestErrorMessage(error, action: action))),
        );
      }
    } finally {
      if (mounted) setState(() => _isRequestingLoan = false);
    }
  }
}

class _BorrowedBookTile extends StatelessWidget {
  const _BorrowedBookTile({
    required this.item,
    required this.index,
    required this.loanId,
    required this.dueAt,
  });

  final Map<String, dynamic> item;
  final int index;
  final String loanId;
  final DateTime? dueAt;

  @override
  Widget build(BuildContext context) {
    final nestedBook = item['book'];
    final title = item['bookTitle'] ??
        item['bookName'] ??
        item['title'] ??
        (nestedBook is Map ? nestedBook['title'] : null);
    final bookId = item['bookId'] ?? item['id'];
    final displayTitle = title?.toString().trim();
    final heading = displayTitle != null && displayTitle.isNotEmpty
        ? displayTitle
        : bookId != null
            ? 'Sách mã $bookId'
            : 'Sách ${index + 1}';
    final copyId = item['copyId'] ?? item['copyCode'];
    final dueDate = dueAt == null
        ? null
        : '${dueAt!.day.toString().padLeft(2, '0')}/'
            '${dueAt!.month.toString().padLeft(2, '0')}/${dueAt!.year}';

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.menu_book_outlined, color: Color(0xFF1876D2)),
      title: Text(heading, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text([
        if (copyId != null) 'Bản sao $copyId',
        if (dueDate != null) 'Hạn trả $dueDate',
        'Phiếu $loanId',
      ].join(' · ')),
    );
  }
}

String _loanRequestErrorMessage(Object error, {required String action}) {
  if (error is TimeoutException) {
    return 'Không thể $action: ${error.message}';
  }
  if (error is DioException) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Không thể $action: server không phản hồi kịp thời.';
    }
    final statusCode = error.response?.statusCode;
    final body = error.response?.data;
    final serverMessage = body is Map
        ? body['message'] ?? body['error'] ?? body['detail']
        : body;
    if (serverMessage != null && serverMessage.toString().trim().isNotEmpty) {
      final message = serverMessage.toString().trim();
      final detail = message.length > 240 ? '${message.substring(0, 240)}…' : message;
      return 'Không thể $action${statusCode == null ? '' : ' (HTTP $statusCode)'}: $detail';
    }
    if (statusCode != null) {
      return 'Không thể $action: BE trả HTTP $statusCode.';
    }
  }
  return 'Không thể $action: $error';
}

class _LoanCard extends StatelessWidget {
  const _LoanCard({required this.loan});

  final LoanResponseDTO loan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFE4E9F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Phiếu ${loan.id}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF25364A),
                  ),
                ),
              ),
              _StatusBadge(status: loan.status),
            ],
          ),
          const Divider(height: 22),
          _LoanField(label: 'Ngày yêu cầu', date: loan.requestedAt),
          _LoanField(label: 'Ngày mượn', date: loan.borrowedAt),
          _LoanField(label: 'Hạn trả', date: loan.dueAt),
          _LoanField(label: 'Ngày trả', date: loan.returnedAt),
          Text(
            '${loan.items.length} đầu sách  ·  Đã gia hạn ${loan.renewCount} lần',
            style: const TextStyle(fontSize: 12, color: Color(0xFF667085)),
          ),
          if (loan.items.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            for (var index = 0; index < loan.items.length; index++)
              _LoanItemTile(item: loan.items[index], index: index),
          ],
          if (loan.rejectionReason?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              loan.rejectionReason!,
              style: const TextStyle(fontSize: 12, color: Colors.redAccent),
            ),
          ],
        ],
      ),
    );
  }
}

class _LoanItemTile extends StatelessWidget {
  const _LoanItemTile({required this.item, required this.index});

  final Map<String, dynamic> item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final nestedBook = item['book'];
    final title = item['bookTitle'] ??
        item['bookName'] ??
        item['title'] ??
        (nestedBook is Map ? nestedBook['title'] : null);
    final bookId = item['bookId'] ?? item['id'];
    final displayTitle = title?.toString().trim();
    final heading = displayTitle != null && displayTitle.isNotEmpty
        ? displayTitle
        : bookId != null
            ? 'Sách mã $bookId'
            : 'Sách ${index + 1}';
    final copyId = item['copyId'] ?? item['copyCode'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.menu_book_outlined,
              size: 17, color: Color(0xFF667085)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  heading,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF344054),
                  ),
                ),
                if (copyId != null)
                  Text(
                    'Mã bản sao: $copyId',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF667085),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoanField extends StatelessWidget {
  const _LoanField({required this.label, required this.date});

  final String label;
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    if (date == null) return const SizedBox.shrink();
    final value = '${date!.day.toString().padLeft(2, '0')}/'
        '${date!.month.toString().padLeft(2, '0')}/${date!.year}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12, color: Color(0xFF475467)),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isBorrowed = status.toUpperCase() == 'BORROWED';
    final color = isBorrowed ? const Color(0xFF25824B) : const Color(0xFF1876D2);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 44, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}