import 'package:flutter/material.dart';

class LoanHistoryScreen extends StatefulWidget {
  const LoanHistoryScreen({super.key});

  @override
  State<LoanHistoryScreen> createState() => _LoanHistoryScreenState();
}

class _LoanHistoryScreenState extends State<LoanHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  _LoanEventType? _selectedType;

  List<_LoanEvent> get _visibleEvents => _sampleEvents.where((event) {
        final matchesType =
            _selectedType == null || event.type == _selectedType;
        final searchableText =
            '${event.bookTitle} ${event.memberName} ${event.memberId}'
                .toLowerCase();
        return matchesType && searchableText.contains(_query);
      }).toList()
        ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final events = _visibleEvents;
    final screenWidth = MediaQuery.sizeOf(context).width;

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
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SummaryChip(
                      label: 'Tất cả',
                      count: _sampleEvents.length,
                      color: const Color(0xFF344054),
                      selected: _selectedType == null,
                      onTap: () => setState(() => _selectedType = null),
                    ),
                    for (final type in _LoanEventType.values)
                      _SummaryChip(
                        label: type.label,
                        count:
                            _sampleEvents.where((e) => e.type == type).length,
                        color: type.color,
                        selected: _selectedType == type,
                        onTap: () => setState(() => _selectedType = type),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 42,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() {
                      _query = value.trim().toLowerCase();
                    }),
                    decoration: InputDecoration(
                      hintText: 'Tìm theo tên sách hoặc người mượn...',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 19),
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
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFFE1E6ED)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFFE1E6ED)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      '${events.length} giao dịch',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF667085),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4DB),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'DỮ LIỆU MẪU',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8A5A00),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: events.isEmpty
                ? const _EmptyHistory()
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      20,
                    ),
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 9),
                    itemBuilder: (context, index) => _LoanEventTile(
                      event: events[index],
                      compact: screenWidth < 380,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LoanEventTile extends StatelessWidget {
  final _LoanEvent event;
  final bool compact;

  const _LoanEventTile({required this.event, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 13 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFE4E9F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: event.type.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(event.type.icon, size: 19, color: event.type.color),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.bookTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF25364A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${event.memberName}  ·  ${event.memberId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _EventBadge(type: event.type),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 11),
            child: Divider(height: 1, color: Color(0xFFEEF1F5)),
          ),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              _EventMeta(
                icon: Icons.schedule,
                label: 'Thời gian',
                value: _formatDateTime(event.occurredAt),
              ),
              _EventMeta(
                icon: event.type == _LoanEventType.renewed
                    ? Icons.event_repeat
                    : Icons.event_available_outlined,
                label: event.dateLabel,
                value: _formatDate(event.relevantDate),
              ),
            ],
          ),
          if (event.note != null) ...[
            const SizedBox(height: 9),
            Text(
              event.note!,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF667085),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EventMeta extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _EventMeta(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF8290A3)),
          const SizedBox(width: 5),
          Text(
            '$label: $value',
            style: const TextStyle(fontSize: 11, color: Color(0xFF475467)),
          ),
        ],
      );
}

class _EventBadge extends StatelessWidget {
  final _LoanEventType type;

  const _EventBadge({required this.type});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: type.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          type.label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: type.color,
          ),
        ),
      );
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? color.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(5),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(5),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: selected
                    ? color.withOpacity(0.35)
                    : const Color(0xFFE1E6ED),
              ),
            ),
            child: Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 12, color: Color(0xFF475467)),
                children: [
                  TextSpan(
                    text: '$label  ',
                    style: TextStyle(
                      color: selected ? color : const Color(0xFF475467),
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: '$count',
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.manage_search,
                  size: 42, color: Color(0xFF98A2B3)),
              const SizedBox(height: 10),
              const Text(
                'Không tìm thấy giao dịch',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Thử từ khóa khác hoặc chọn loại giao dịch khác.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blueGrey.shade500, fontSize: 12),
              ),
            ],
          ),
        ),
      );
}

enum _LoanEventType {
  borrow('Mượn', Color(0xFF1876D2), Icons.menu_book_outlined),
  returned('Trả', Color(0xFF25824B), Icons.assignment_turned_in_outlined),
  renewed('Gia hạn', Color(0xFFB66A0A), Icons.update_rounded);

  const _LoanEventType(this.label, this.color, this.icon);

  final String label;
  final Color color;
  final IconData icon;
}

class _LoanEvent {
  final _LoanEventType type;
  final String bookTitle;
  final String memberName;
  final String memberId;
  final DateTime occurredAt;
  final DateTime relevantDate;
  final String dateLabel;
  final String? note;

  const _LoanEvent({
    required this.type,
    required this.bookTitle,
    required this.memberName,
    required this.memberId,
    required this.occurredAt,
    required this.relevantDate,
    required this.dateLabel,
    this.note,
  });
}

final _sampleEvents = <_LoanEvent>[
  _LoanEvent(
    type: _LoanEventType.borrow,
    bookTitle: 'Dế Mèn phiêu lưu ký',
    memberName: 'Lê Văn C',
    memberId: 'user-003',
    occurredAt: DateTime(2026, 10, 18, 9, 15),
    relevantDate: DateTime(2026, 11, 1),
    dateLabel: 'Hạn trả',
  ),
  _LoanEvent(
    type: _LoanEventType.renewed,
    bookTitle: 'Dế Mèn phiêu lưu ký',
    memberName: 'Lê Văn C',
    memberId: 'user-003',
    occurredAt: DateTime(2026, 10, 19, 10, 20),
    relevantDate: DateTime(2026, 11, 15),
    dateLabel: 'Hạn mới',
    note: 'Gia hạn thêm 14 ngày.',
  ),
  _LoanEvent(
    type: _LoanEventType.borrow,
    bookTitle: 'Clean Code',
    memberName: 'Lê Văn C',
    memberId: 'user-003',
    occurredAt: DateTime(2026, 10, 16, 14, 5),
    relevantDate: DateTime(2026, 10, 30),
    dateLabel: 'Hạn trả',
  ),
  _LoanEvent(
    type: _LoanEventType.returned,
    bookTitle: 'Nhà giả kim',
    memberName: 'Phạm Thị D',
    memberId: 'user-004',
    occurredAt: DateTime(2026, 10, 15, 16, 42),
    relevantDate: DateTime(2026, 10, 15),
    dateLabel: 'Ngày trả',
    note: 'Đã nhận lại sách.',
  ),
  _LoanEvent(
    type: _LoanEventType.renewed,
    bookTitle: 'Clean Code',
    memberName: 'Lê Văn C',
    memberId: 'user-003',
    occurredAt: DateTime(2026, 10, 14, 11, 10),
    relevantDate: DateTime(2026, 11, 13),
    dateLabel: 'Hạn mới',
    note: 'Gia hạn thêm 14 ngày.',
  ),
  _LoanEvent(
    type: _LoanEventType.returned,
    bookTitle: 'Đắc nhân tâm',
    memberName: 'Lê Văn C',
    memberId: 'user-003',
    occurredAt: DateTime(2026, 10, 12, 13, 30),
    relevantDate: DateTime(2026, 10, 12),
    dateLabel: 'Ngày trả',
    note: 'Đã nhận lại sách.',
  ),
];

String _formatDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/'
    '${date.year}';

String _formatDateTime(DateTime date) =>
    '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:'
    '${date.minute.toString().padLeft(2, '0')}';
