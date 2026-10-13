import 'package:flutter/material.dart';

// ───────────────────────── Màu sắc ─────────────────────────
class _C {
  static const background = Color(0xFFF5F7FB);
  static const primary = Color(0xFF2563EB);
  static const textDark = Color(0xFF1E293B);
  static const textGrey = Color(0xFF94A3B8);
  static const border = Color(0xFFE8ECF3);
  static const headerBg = Color(0xFFF8FAFC);
  static const danger = Color(0xFFEF4444);
}

// ───────────────────────── Dữ liệu mẫu ─────────────────────────
class _Category {
  final String name;
  final String description;
  final int bookCount;
  const _Category(this.name, this.description, this.bookCount);
}

const _categories = [
  _Category('Văn học', 'Sách văn học trong và ngoài nước', 120),
  _Category('Kỹ năng sống', 'Phát triển bản thân', 85),
  _Category('Công nghệ', 'Lập trình, công nghệ thông tin', 64),
  _Category('Kinh tế', 'Quản trị, kinh doanh', 42),
  _Category('Tiểu thuyết', 'Truyện dài, tiểu thuyết', 98),
];

// ───────────────────────── Trang Thể loại ─────────────────────────
class CategoryPage extends StatefulWidget {
  /// Gọi khi bấm nút quay lại. Nếu null thì dùng Navigator.maybePop.
  final VoidCallback? onBack;

  const CategoryPage({super.key, this.onBack});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  static const _totalPages = 3;
  int _currentPage = 1;

  void _goToPage(int page) {
    setState(() => _currentPage = page.clamp(1, _totalPages));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildToolbar(),
            const SizedBox(height: 20),
            _CategoryTable(categories: _categories),
            const SizedBox(height: 16),
            _buildPagination(),
          ],
        ),
      ),
    );
  }

  // Tiêu đề: nút quay lại, "Thể loại", nút làm mới
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: widget.onBack ?? () => Navigator.maybePop(context),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.chevron_left_rounded,
                size: 26, color: _C.textDark),
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          'Thể loại',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _C.textDark,
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Làm mới',
          onPressed: () {},
          icon: const Icon(Icons.refresh_rounded, color: _C.textGrey),
        ),
      ],
    );
  }

  // Ô tìm kiếm + nút thêm
  Widget _buildToolbar() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: TextField(
              style: const TextStyle(fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Tìm theo tên thể loại...',
                hintStyle:
                    const TextStyle(color: _C.textGrey, fontSize: 13.5),
                prefixIcon:
                    const Icon(Icons.search, size: 20, color: _C.textGrey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.zero,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _C.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _C.primary),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          height: 44,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Thêm thể loại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              textStyle:
                  const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Phân trang
  Widget _buildPagination() {
    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PageButton(
            icon: Icons.chevron_left_rounded,
            onTap: () => _goToPage(_currentPage - 1),
          ),
          for (int p = 1; p <= _totalPages; p++)
            _PageButton(
              label: '$p',
              selected: p == _currentPage,
              onTap: () => _goToPage(p),
            ),
          const _PageButton(label: '...'),
          _PageButton(
            icon: Icons.chevron_right_rounded,
            onTap: () => _goToPage(_currentPage + 1),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Bảng ─────────────────────────
class _CategoryTable extends StatelessWidget {
  final List<_Category> categories;
  const _CategoryTable({required this.categories});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: _C.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            const _HeaderRow(),
            for (int i = 0; i < categories.length; i++)
              _DataRow(index: i + 1, category: categories[i]),
          ],
        ),
      ),
    );
  }
}

// Độ rộng các cột dùng chung cho header và dòng dữ liệu
class _Cols {
  static const index = 56.0;
  static const actions = 150.0;
  static const nameFlex = 3;
  static const descFlex = 5;
  static const countFlex = 2;
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w700,
      color: _C.textDark,
    );
    return Container(
      color: _C.headerBg,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: const Row(
        children: [
          SizedBox(
            width: _Cols.index,
            child: Text('#', textAlign: TextAlign.center, style: style),
          ),
          Expanded(flex: _Cols.nameFlex, child: Text('Tên thể loại', style: style)),
          Expanded(flex: _Cols.descFlex, child: Text('Mô tả', style: style)),
          Expanded(
            flex: _Cols.countFlex,
            child: Text('Số sách', textAlign: TextAlign.center, style: style),
          ),
          SizedBox(
            width: _Cols.actions,
            child: Text('Thao tác', textAlign: TextAlign.center, style: style),
          ),
        ],
      ),
    );
  }
}

class _DataRow extends StatefulWidget {
  final int index;
  final _Category category;
  const _DataRow({required this.index, required this.category});

  @override
  State<_DataRow> createState() => _DataRowState();
}

class _DataRowState extends State<_DataRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 13, color: _C.textDark);
    final c = widget.category;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _hovered ? const Color(0xFFF1F5FD) : Colors.white,
          border: const Border(top: BorderSide(color: _C.border)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: _Cols.index,
              child: Text('${widget.index}',
                  textAlign: TextAlign.center, style: style),
            ),
            Expanded(
              flex: _Cols.nameFlex,
              child: Text(c.name, style: style.copyWith(fontWeight: FontWeight.w500)),
            ),
            Expanded(
              flex: _Cols.descFlex,
              child: Text(c.description,
                  overflow: TextOverflow.ellipsis, style: style),
            ),
            Expanded(
              flex: _Cols.countFlex,
              child: Text('${c.bookCount}',
                  textAlign: TextAlign.center, style: style),
            ),
            SizedBox(
              width: _Cols.actions,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionIcon(
                    icon: Icons.edit_outlined,
                    tooltip: 'Sửa',
                    color: _C.primary,
                    onTap: () {},
                  ),
                  _ActionIcon(
                    icon: Icons.edit_note_rounded,
                    tooltip: 'Chi tiết',
                    color: _C.primary,
                    onTap: () {},
                  ),
                  _ActionIcon(
                    icon: Icons.delete_outline_rounded,
                    tooltip: 'Xóa',
                    color: _C.danger,
                    onTap: () {},
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

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: color),
      visualDensity: VisualDensity.compact,
      splashRadius: 18,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }
}

// ───────────────────────── Nút phân trang ─────────────────────────
class _PageButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  const _PageButton({
    this.label,
    this.icon,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEFF4FF) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? _C.primary : _C.border,
            ),
          ),
          child: icon != null
              ? Icon(icon, size: 20, color: _C.textDark)
              : Text(
                  label ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? _C.primary : _C.textDark,
                  ),
                ),
        ),
      ),
    );
  }
}