import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Ô tìm kiếm + nút thêm thể loại.
class CategoryToolbar extends StatefulWidget {
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onCreate;

  const CategoryToolbar({
    super.key,
    required this.onSearchChanged,
    required this.onCreate,
  });

  @override
  State<CategoryToolbar> createState() => _CategoryToolbarState();
}

class _CategoryToolbarState extends State<CategoryToolbar> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: TextField(
              controller: _searchController,
              onChanged: widget.onSearchChanged,
              style: const TextStyle(fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Tìm theo tên thể loại...',
                hintStyle:
                    const TextStyle(color: AppColors.textGrey, fontSize: 13.5),
                prefixIcon: const Icon(Icons.search,
                    size: 20, color: AppColors.textGrey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.zero,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          height: 44,
          child: ElevatedButton.icon(
            onPressed: widget.onCreate,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Thêm thể loại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
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
}
