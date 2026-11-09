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
  final Map<String, String> _processingLoanActions = {};

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(loanCurrentUserInfoProvider);
    final userRoles = currentUser?.roles.join(',') ?? '';

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
            onPressed: () {
              ref.invalidate(adminLoansProvider(userRoles));
              ref.invalidate(loanBookListProvider);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: currentUser == null
          ? _ErrorView(
              message: 'Phiên đăng nhập không có thông tin người dùng.',
              onRetry: () => ref.invalidate(loanCurrentUserInfoProvider),
            )
          : ref.watch(adminLoansProvider(userRoles)).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _ErrorView(
            message: _loanRequestErrorMessage(
              error,
              action: 'tải danh sách loans quản trị',
            ),
            onRetry: () => ref.invalidate(adminLoansProvider(userRoles)),
          ),
          data: (page) => _buildLoanList(currentUser.id, userRoles, page),
        ),
    );
  }

  Widget _buildLoanList(
    String userId,
    String userRoles,
    PageDTO<LoanResponseDTO> page,
  ) {
    final loans = page.content.where((loan) {
      final searchable =
          '${loan.id} ${loan.userId} ${loan.status} ${loan.items}'.toLowerCase();
      return searchable.contains(_query);
    }).toList()
      ..sort((a, b) =>
          (b.requestedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(a.requestedAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
    final borrowedLoans = loans
        .where((loan) => loan.status.toUpperCase() == 'BORROWED')
        .toList();
    final requestedLoans = loans
      .where((loan) => loan.status.toUpperCase() == 'REQUESTED')
      .toList();
    final borrowedBookCount = borrowedLoans.fold<int>(
      0,
      (count, loan) => count + loan.items.length,
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminLoansProvider(userRoles));
        await ref.read(adminLoansProvider(userRoles).future);
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
              onPressed: _isRequestingLoan
                  ? null
                  : () => _requestLoan(userId, userRoles),
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
            'Yêu cầu chờ duyệt (${requestedLoans.length})',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF25364A),
            ),
          ),
          const SizedBox(height: 8),
          if (requestedLoans.isEmpty)
            const Text(
              'Không có yêu cầu mượn đang chờ duyệt.',
              style: TextStyle(fontSize: 12, color: Color(0xFF667085)),
            )
          else
            for (final loan in requestedLoans) ...[
              _RequestedLoanCard(
                loan: loan,
                processingAction: _processingLoanActions[loan.id],
                onTap: () => _showLoanDetails(loan),
                onApprove: () => _approveLoan(loan, userId, userRoles),
                onReject: () => _rejectLoan(loan, userId, userRoles),
              ),
              const SizedBox(height: 8),
            ],
          const SizedBox(height: 18),
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
                  onTap: () => _showLoanDetails(loan),
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
              _LoanCard(
                loan: loan,
                onTap: () => _showLoanDetails(loan),
              ),
              const SizedBox(height: 9),
            ],
        ],
      ),
    );
  }

  void _showLoanDetails(LoanResponseDTO loan) {
    showDialog<void>(
      context: context,
      builder: (context) => _LoanDetailsDialog(loan: loan),
    );
  }

  Future<void> _approveLoan(
    LoanResponseDTO loan,
    String adminUserId,
    String userRoles,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duyệt yêu cầu mượn'),
        content: Text('Duyệt phiếu ${loan.id} của user ${loan.userId}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xác nhận duyệt'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _processingLoanActions[loan.id] = 'approve');
    try {
      final approvedLoan = await ref
          .read(loanRemoteDataSourceProvider)
          .approveLoan(
            loanId: loan.id,
            adminUserId: adminUserId,
            userRoles: userRoles,
          )
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () => throw TimeoutException(
              'BE không phản hồi khi duyệt phiếu sau 20 giây.',
            ),
          );
      ref.invalidate(adminLoansProvider(userRoles));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã duyệt phiếu ${approvedLoan.id}: ${approvedLoan.status}.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _loanRequestErrorMessage(error, action: 'duyệt phiếu mượn'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processingLoanActions.remove(loan.id));
    }
  }

  Future<void> _rejectLoan(
    LoanResponseDTO loan,
    String adminUserId,
    String userRoles,
  ) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối yêu cầu mượn'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Từ chối phiếu ${loan.id} của user ${loan.userId}?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Lý do từ chối (không bắt buộc)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xác nhận từ chối'),
          ),
        ],
      ),
    );
    final reason = reasonController.text.trim();
    reasonController.dispose();
    if (confirmed != true || !mounted) return;

    setState(() => _processingLoanActions[loan.id] = 'reject');
    try {
      final rejectedLoan = await ref
          .read(loanRemoteDataSourceProvider)
          .rejectLoan(
            loanId: loan.id,
            adminUserId: adminUserId,
            userRoles: userRoles,
            reason: reason.isEmpty ? null : reason,
          )
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () => throw TimeoutException(
              'BE không phản hồi khi từ chối phiếu sau 20 giây.',
            ),
          );
      ref.invalidate(adminLoansProvider(userRoles));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã từ chối phiếu ${rejectedLoan.id}: ${rejectedLoan.status}.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _loanRequestErrorMessage(error, action: 'từ chối phiếu mượn'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processingLoanActions.remove(loan.id));
    }
  }

  Future<void> _requestLoan(String userId, String userRoles) async {
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
      ref.invalidate(adminLoansProvider(userRoles));
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

class _RequestedLoanCard extends StatelessWidget {
  const _RequestedLoanCard({
    required this.loan,
    required this.processingAction,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
  });

  final LoanResponseDTO loan;
  final String? processingAction;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(7),
        side: const BorderSide(color: Color(0xFFE4E9F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: InkWell(
                onTap: onTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phiếu ${loan.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF25364A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${loan.items.length} sách · User ${loan.userId}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 6,
                runSpacing: 4,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: processingAction == null ? onApprove : null,
                    icon: processingAction == 'approve'
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check, size: 17),
                    label: Text(
                      processingAction == 'approve' ? 'Đang duyệt' : 'Duyệt',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: processingAction == null ? onReject : null,
                    icon: processingAction == 'reject'
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.close, size: 17),
                    label: Text(
                      processingAction == 'reject'
                          ? 'Đang từ chối'
                          : 'Từ chối',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BorrowedBookTile extends StatelessWidget {
  const _BorrowedBookTile({
    required this.item,
    required this.index,
    required this.loanId,
    required this.dueAt,
    required this.onTap,
  });

  final Map<String, dynamic> item;
  final int index;
  final String loanId;
  final DateTime? dueAt;
  final VoidCallback onTap;

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
      onTap: onTap,
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
  const _LoanCard({required this.loan, required this.onTap});

  final LoanResponseDTO loan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(7),
        side: const BorderSide(color: Color(0xFFE4E9F0)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
        ),
      ),
    );
  }
}

class _LoanDetailsDialog extends ConsumerWidget {
  const _LoanDetailsDialog({required this.loan});

  final LoanResponseDTO loan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(loanUserDetailsProvider(loan.userId));
    return AlertDialog(
      title: const Text('Chi tiết mượn - trả'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              userAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailSection(
                      title: 'Người mượn',
                      rows: [_DetailRow('Mã người dùng', loan.userId)],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _loanRequestErrorMessage(
                        error,
                        action: 'tải thông tin người mượn',
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () =>
                          ref.invalidate(loanUserDetailsProvider(loan.userId)),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Thử tải lại'),
                    ),
                  ],
                ),
                data: (user) => _DetailSection(
                  title: 'Người mượn',
                  rows: [
                    _DetailRow('Mã người dùng', user.id),
                    _DetailRow('Họ tên', user.fullName),
                    _DetailRow('Email', user.email),
                    if (user.phone?.isNotEmpty == true)
                      _DetailRow('Điện thoại', user.phone!),
                    _DetailRow('Vai trò', user.role),
                    _DetailRow('Trạng thái', user.status),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _DetailSection(
                title: 'Phiếu mượn',
                rows: [
                  _DetailRow('Mã phiếu', loan.id),
                  _DetailRow('Trạng thái', loan.status),
                  _DetailRow('Số lần gia hạn', '${loan.renewCount}'),
                  _DetailRow('Ngày yêu cầu', _formatDetailDate(loan.requestedAt)),
                  _DetailRow('Ngày duyệt', _formatDetailDate(loan.approvedAt)),
                  _DetailRow('Ngày mượn', _formatDetailDate(loan.borrowedAt)),
                  _DetailRow('Hạn trả', _formatDetailDate(loan.dueAt)),
                  _DetailRow('Ngày trả', _formatDetailDate(loan.returnedAt)),
                  if (loan.rejectionReason?.isNotEmpty == true)
                    _DetailRow('Lý do từ chối', loan.rejectionReason!),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Sách trong phiếu (${loan.items.length})',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              if (loan.items.isEmpty)
                const Text('Phiếu chưa có thông tin sách.')
              else
                for (var index = 0; index < loan.items.length; index++)
                  _LoanDetailItem(item: loan.items[index], index: index),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.rows});

  final String title;
  final List<_DetailRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        for (final row in rows) row,
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(label, style: const TextStyle(color: Color(0xFF667085))),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _LoanDetailItem extends StatelessWidget {
  const _LoanDetailItem({required this.item, required this.index});

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
    final heading = title?.toString().trim().isNotEmpty == true
        ? title.toString()
        : bookId != null
            ? 'Sách mã $bookId'
            : 'Sách ${index + 1}';
    final copyId = item['copyId'] ?? item['copyCode'];
    final fine = item['fineAmount'];

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.menu_book_outlined),
      title: Text(heading),
      subtitle: Text([
        if (item['itemStatus'] != null) 'Trạng thái: ${item['itemStatus']}',
        if (copyId != null) 'Bản sao: $copyId',
        if (item['returnedAt'] != null) 'Đã trả: ${item['returnedAt']}',
        if (fine != null) 'Tiền phạt: $fine',
      ].join(' · ')),
    );
  }
}

String _formatDetailDate(DateTime? date) {
  if (date == null) return 'Chưa có';
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
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