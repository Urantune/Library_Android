import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Dữ liệu trả về từ form.
class CategoryFormResult {
  final String name;
  final String description;
  const CategoryFormResult(this.name, this.description);
}

/// Form dùng chung cho cả thêm và sửa thể loại.
class CategoryFormDialog extends StatefulWidget {
  final String title;
  final String submitLabel;
  final String initialName;
  final String initialDescription;

  /// Các tên đã tồn tại, dùng để chặn trùng tên.
  final List<String> takenNames;

  const CategoryFormDialog({
    super.key,
    required this.title,
    required this.submitLabel,
    this.initialName = '',
    this.initialDescription = '',
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
