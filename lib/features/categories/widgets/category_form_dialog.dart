import 'package:flutter/material.dart';

import '../models/book_category.dart';
import 'app_colors.dart';

class CategoryFormResult {
  final String name;
  final String description;

  final String? parentId;
  const CategoryFormResult(this.name, this.description, {this.parentId});
}

class CategoryFormDialog extends StatefulWidget {
  final String title;
  final String submitLabel;
  final String initialName;
  final String initialDescription;

  final List<BookCategory> parentOptions;

  final String? initialParentId;

  final bool parentLocked;

  final List<String> takenNames;

  const CategoryFormDialog({
    super.key,
    required this.title,
    required this.submitLabel,
    this.initialName = '',
    this.initialDescription = '',
    this.parentOptions = const [],
    this.initialParentId,
    this.parentLocked = false,
    this.takenNames = const [],
  });

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController =
      TextEditingController(text: widget.initialName);
  late final TextEditingController _descController =
      TextEditingController(text: widget.initialDescription);

  late String? _parentId = widget.initialParentId;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(CategoryFormResult(
      _nameController.text.trim(),
      _descController.text.trim(),
      parentId: _parentId,
    ));
  }

  InputDecoration _decoration(String label, String hint) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color),
        );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13.5),
      enabledBorder: border(AppColors.border),
      focusedBorder: border(AppColors.primary),
      errorBorder: border(AppColors.danger),
      focusedErrorBorder: border(AppColors.danger),
    );
  }

  Widget _buildParentField() {
    final options = widget.parentOptions;
    final selected = widget.initialParentId;
    final missing = selected != null && !options.any((c) => c.id == selected);

    return DropdownButtonFormField<String?>(
      value: _parentId,
      isExpanded: true,
      decoration: _decoration('Danh mục cha', '').copyWith(
        helperText: widget.parentLocked
            ? 'Thể loại này đang có thể loại con nên không thể trở thành thể loại con.'
            : 'Để mặc định nếu đây là thể loại cha.',
        helperMaxLines: 2,
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('— Không có (thể loại cha) —'),
        ),
        if (missing)
          DropdownMenuItem<String?>(
            value: selected,
            child: Text('Mã $selected (không khả dụng)'),
          ),
        for (final c in options)
          DropdownMenuItem<String?>(
            value: c.id,
            child: Text(c.name, overflow: TextOverflow.ellipsis),
          ),
      ],
            onChanged: widget.parentLocked
          ? null
          : (value) => setState(() => _parentId = value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(
        widget.title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: _decoration('Tên thể loại', 'Ví dụ: Văn học'),
                validator: (value) {
                  final name = (value ?? '').trim();
                  if (name.isEmpty) return 'Vui lòng nhập tên thể loại';
                  final exists = widget.takenNames.any(
                    (n) => n.trim().toLowerCase() == name.toLowerCase(),
                  );
                  if (exists) return 'Tên thể loại này đã tồn tại';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: _decoration('Mô tả', 'Mô tả ngắn về thể loại'),
              ),
              const SizedBox(height: 16),
              _buildParentField(),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy', style: TextStyle(color: AppColors.textGrey)),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(widget.submitLabel),
        ),
      ],
    );
  }
}
