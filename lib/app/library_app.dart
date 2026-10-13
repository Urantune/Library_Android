import 'package:flutter/material.dart';

import '../features/authors/presentation/screens/author_list_screen.dart';
import '../features/categories/presentation/category_page.dart';

// ───────────────────────── Màu sắc ─────────────────────────
class AppColors {
  static const sidebar = Color(0xFF1B2F4E);
  static const background = Color(0xFFF5F7FB);
  static const primary = Color(0xFF2563EB);
  static const textDark = Color(0xFF1E293B);
  static const textGrey = Color(0xFF94A3B8);
  static const green = Color(0xFF16A34A);
  static const border = Color(0xFFE8ECF3);
}

class LibraryApp extends StatelessWidget {
  const LibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Thư viện số',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorSchemeSeed: AppColors.primary,
      ),
      home: const DashboardPage(),
    );
  }
}

// ───────────────────────── Khung chính (điều hướng) ─────────────────────────
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Vị trí các mục trong sidebar
  static const int _dashboardIndex = 0;
  static const int _authorIndex = 2;
  static const int _categoryIndex = 3;

  int _selectedIndex = _dashboardIndex;

  Widget _buildPage() {
    switch (_selectedIndex) {
      case _dashboardIndex:
        return const DashboardHome();
      case _authorIndex:
        return const AuthorListScreen();
      case _categoryIndex:
        return CategoryPage(
          onBack: () => setState(() => _selectedIndex = _dashboardIndex),
        );
      default:
        return const _PlaceholderPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            selectedIndex: _selectedIndex,
            onSelected: (i) => setState(() => _selectedIndex = i),
          ),
          Expanded(
            child: Column(
              children: [
                const TopBar(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: KeyedSubtree(
                      key: ValueKey(_selectedIndex),
                      child: _buildPage(),
                    ),
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

// Trang tạm cho các mục chưa làm
class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Trang này đang được phát triển',
        style: TextStyle(color: AppColors.textGrey, fontSize: 14),
      ),
    );
  }
}

// ───────────────────────── Sidebar ─────────────────────────
class _MenuItem {
  final IconData icon;
  final String label;
  const _MenuItem(this.icon, this.label);
}

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const _mainItems = [
    _MenuItem(Icons.home_rounded, 'Dashboard'),
    _MenuItem(Icons.menu_book_rounded, 'Sách'),
    _MenuItem(Icons.person_outline_rounded, 'Tác giả'),
    _MenuItem(Icons.category_outlined, 'Thể loại'),
    _MenuItem(Icons.apartment_rounded, 'Nhà xuất bản'),
    _MenuItem(Icons.people_outline_rounded, 'Người dùng'),
    _MenuItem(Icons.swap_horiz_rounded, 'Mượn - Trả'),
    _MenuItem(Icons.bookmark_border_rounded, 'Đặt trước'),
    _MenuItem(Icons.notifications_none_rounded, 'Thông báo'),
  ];

  static const _bottomItems = [
    _MenuItem(Icons.bar_chart_rounded, 'Báo cáo'),
    _MenuItem(Icons.settings_outlined, 'Quản trị hệ thống'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      color: AppColors.sidebar,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.local_library_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  'Thư viện số',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          for (int i = 0; i < _mainItems.length; i++)
            _SidebarTile(
              item: _mainItems[i],
              selected: selectedIndex == i,
              onTap: () => onSelected(i),
            ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: Colors.white.withOpacity(0.12), height: 1),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < _bottomItems.length; i++)
            _SidebarTile(
              item: _bottomItems[i],
              selected: selectedIndex == _mainItems.length + i,
              onTap: () => onSelected(_mainItems.length + i),
            ),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatefulWidget {
  final _MenuItem item;
  final bool selected;
  final VoidCallback onTap;
  const _SidebarTile({
    required this.item,
    required this.onTap,
    this.selected = false,
  });

  @override
  State<_SidebarTile> createState() => _SidebarTileState();
}

class _SidebarTileState extends State<_SidebarTile> {
  static const _hoverColor = Color(0xFFDEE034);
  static const _duration = Duration(milliseconds: 220);
  static const _curve = Curves.easeOutCubic;

  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final hovering = _hovered && !selected; // chỉ áp dụng cho thẻ chưa chọn

    final textColor = selected
        ? AppColors.primary
        : hovering
            ? _hoverColor
            : Colors.white;
    final iconColor = selected
        ? AppColors.primary
        : hovering
            ? _hoverColor
            : Colors.white70;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: _duration,
        curve: _curve,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        // Thẻ nổi lên nhẹ khi hover
        transform: Matrix4.translationValues(0, hovering ? -2 : 0, 0),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white
              : hovering
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white.withOpacity(0),
          borderRadius: BorderRadius.circular(10),
          boxShadow: hovering
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: iconColor),
                    duration: _duration,
                    curve: _curve,
                    builder: (context, color, _) =>
                        Icon(widget.item.icon, size: 20, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: _duration,
                      curve: _curve,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                        color: textColor,
                      ),
                      child: Text(
                        widget.item.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Nội dung trang Dashboard ─────────────────────────
class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Xin chào, Nguyễn Văn A 👋',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hôm nay là ngày ${now.day} tháng ${now.month}, ${now.year}',
            style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
          ),
          const SizedBox(height: 24),
          const StatsRow(),
          const SizedBox(height: 24),
          const PopularBooksSection(),
        ],
      ),
    );
  }
}

// ───────────────────────── Top bar ─────────────────────────
class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: Colors.white,
      child: Row(
        children: [
          // Ô tìm kiếm
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm sách, tác giả, thể loại...',
                    hintStyle: const TextStyle(
                        color: AppColors.textGrey, fontSize: 13),
                    prefixIcon: const Icon(Icons.search,
                        size: 20, color: AppColors.textGrey),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Thông tin người dùng
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFDCE6FA),
            child: Icon(Icons.person, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Nguyễn Văn A',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark),
              ),
              Text(
                'Thủ thư',
                style: TextStyle(fontSize: 11, color: AppColors.textGrey),
              ),
            ],
          ),
          const SizedBox(width: 16),
          const Icon(Icons.notifications_none_rounded,
              color: AppColors.textDark),
        ],
      ),
    );
  }
}

// ───────────────────────── Thẻ thống kê ─────────────────────────
class StatsRow extends StatelessWidget {
  const StatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Expanded(
          child: StatCard(
            icon: Icons.menu_book_rounded,
            color: Color(0xFF2563EB),
            label: 'Tổng sách',
            value: '1,245',
            change: '+ 12%',
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: StatCard(
            icon: Icons.import_contacts_rounded,
            color: Color(0xFFF59E0B),
            label: 'Đang mượn',
            value: '86',
            change: '+ 33%',
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: StatCard(
            icon: Icons.bookmark_rounded,
            color: Color(0xFFEF4444),
            label: 'Đặt trước',
            value: '24',
            change: '+ 55%',
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: StatCard(
            icon: Icons.person_rounded,
            color: Color(0xFF06B6D4),
            label: 'Người dùng',
            value: '532',
            change: '+ 58%',
          ),
        ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String change;

  const StatCard({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.change,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            change,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.green,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Sách được mượn nhiều ─────────────────────────
class _Book {
  final String title;
  final String author;
  final int borrowCount;
  final Color color;
  const _Book(this.title, this.author, this.borrowCount, this.color);
}

class PopularBooksSection extends StatelessWidget {
  const PopularBooksSection({super.key});

  static const _books = [
    _Book('Dế Mèn phiêu lưu ký', 'Nguyễn Nhật Ánh', 30, Color(0xFF7CB342)),
    _Book('Nhà giả kim', 'Paulo Coelho', 28, Color(0xFFE67E22)),
    _Book('Đắc nhân tâm', 'Dale Carnegie', 25, Color(0xFF212121)),
    _Book('Tuổi trẻ đáng giá bao nhiêu', 'Rosie Nguyễn', 20, Color(0xFF1E3A8A)),
    _Book('Clean Code', 'Robert C. Martin', 18, Color(0xFF111827)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sách được mượn nhiều',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.chevron_right, size: 18),
                label: const Text('Xem tất cả'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < _books.length; i++) ...[
                if (i > 0) const SizedBox(width: 14),
                Expanded(child: BookCard(book: _books[i])),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class BookCard extends StatelessWidget {
  final _Book book;
  const BookCard({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bìa sách (placeholder – chưa dùng hình)
          Center(
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [book.color, book.color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.menu_book_rounded,
                      color: Colors.white70, size: 32),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            book.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.5, color: AppColors.textGrey),
          ),
          const SizedBox(height: 4),
          Text(
            '${book.borrowCount} lượt',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Dùng chung ─────────────────────────
BoxDecoration _cardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
