import 'package:flutter/material.dart';

import '../models/my_loan.dart';
import '../services/dashboard_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';

/// "Sách đã mượn" của người dùng hiện tại.
///
/// Dữ liệu mẫu thuộc phạm vi home; không gọi API circulation của Trí.
class MyLoansScreen extends StatefulWidget {
  const MyLoansScreen({super.key});

  @override
  State<MyLoansScreen> createState() => _MyLoansScreenState();
}

class _MyLoansScreenState extends State<MyLoansScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  MyLoanStatus? _filter;

  List<MyLoan> get _loans => DashboardService.getMyLoans();

  List<MyLoan> get _visibleLoans {
    final query = _query.trim().toLowerCase();
    return _loans.where((loan) {
      final matchesStatus = _filter == null || loan.status == _filter;
      final matchesQuery = query.isEmpty ||
          '${loan.bookTitle} ${loan.author}'.toLowerCase().contains(query);
      return matchesStatus && matchesQuery;
    }).toList()
      ..sort((a, b) => b.borrowedAt.compareTo(a.borrowedAt));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loans = _loans;
    final visible = _visibleLoans;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Sách đã mượn',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF4FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFDCE6FA)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 18, color: AppColors.primary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Dữ liệu mẫu. Sẽ kết nối API mượn trả khi '
                          'circulation-service sẵn sàng.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FilterChip(
                      label: 'Tất cả (${loans.length})',
                      selected: _filter == null,
                      onTap: () => setState(() => _filter = null),
                    ),
                    for (final status in MyLoanStatus.values)
                      _FilterChip(
                        label:
                            '${status.label} (${loans.where((loan) => loan.status == status).length})',
                        selected: _filter == status,
                        onTap: () => setState(() => _filter = status),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên sách hoặc tác giả...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Xóa tìm kiếm',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close, size: 18),
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE1E6ED)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE1E6ED)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _LoanCard(loan: visible[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  final MyLoan loan;

  const _LoanCard({required this.loan});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(loan.status);
    final statusBackground = _statusBackground(loan.status);
    final now = DateTime.now();

    String dateLine;
    if (loan.status == MyLoanStatus.returned) {
      dateLine = 'Đã trả: ${_formatDate(loan.returnedAt ?? loan.dueAt)}';
    } else if (loan.status == MyLoanStatus.overdue) {
      final days = now.difference(loan.dueAt).inDays;
      dateLine = 'Quá hạn $days ngày · Hạn trả: ${_formatDate(loan.dueAt)}';
    } else {
      final days = loan.dueAt.difference(now).inDays;
      dateLine = 'Còn $days ngày · Hạn trả: ${_formatDate(loan.dueAt)}';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFFE6EDFF),
            child: Text(
              loan.bookTitle.isEmpty ? '?' : loan.bookTitle[0].toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF3157B7),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        loan.bookTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBackground,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        loan.status.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  loan.author,
                  style: const TextStyle(color: AppColors.textGrey),
                ),
                const SizedBox(height: 10),
                Text(
                  'Mượn: ${_formatDate(loan.borrowedAt)}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  dateLine,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: selected ? Colors.white : AppColors.textDark,
      ),
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFE1E6ED)),
      showCheckmark: false,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_outlined, size: 52, color: AppColors.textGrey),
            SizedBox(height: 12),
            Text('Không có lượt mượn nào phù hợp.'),
          ],
        ),
      ),
    );
  }
}

Color _statusColor(MyLoanStatus status) => switch (status) {
      MyLoanStatus.borrowing => const Color(0xFF1876D2),
      MyLoanStatus.overdue => const Color(0xFFB42318),
      MyLoanStatus.returned => const Color(0xFF16713A),
    };

Color _statusBackground(MyLoanStatus status) => switch (status) {
      MyLoanStatus.borrowing => const Color(0xFFE3F0FF),
      MyLoanStatus.overdue => const Color(0xFFFFE9E7),
      MyLoanStatus.returned => const Color(0xFFE2F6E9),
    };

String _formatDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/'
    '${date.year}';
