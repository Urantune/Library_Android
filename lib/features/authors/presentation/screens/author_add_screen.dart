import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/author.dart';
import '../providers/author_provider.dart';

class AuthorAddScreen extends ConsumerStatefulWidget {
  final Author? author; // Nếu có author thì là chế độ Sửa, không có là Thêm mới

  const AuthorAddScreen({super.key, this.author});

  @override
  ConsumerState<AuthorAddScreen> createState() => _AuthorAddScreenState();
}

class _AuthorAddScreenState extends ConsumerState<AuthorAddScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _countryController;
  late final TextEditingController _bioController;

  DateTime? _birthDate;
  late String _status;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.author?.name ?? '');
    _countryController =
        TextEditingController(text: widget.author?.country ?? '');
    _bioController = TextEditingController(text: widget.author?.bio ?? '');
    _birthDate = widget.author?.birthDate;
    _status = widget.author?.status ?? 'ACTIVE';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countryController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25),
      firstDate: DateTime(1),
      lastDate: now,
      helpText: 'Chọn ngày sinh',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );

    if (selectedDate != null && mounted) {
      setState(() => _birthDate = selectedDate);
    }
  }

  Future<void> _saveAuthor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final now = DateTime.now();

    final author = Author(
      id: widget.author?.id ?? '',
      name: _nameController.text.trim(),
      bio: _bioController.text.trim().isEmpty
          ? null
          : _bioController.text.trim(),
      birthDate: _birthDate,
      country: _countryController.text.trim().isEmpty
          ? null
          : _countryController.text.trim(),
      status: _status,
      createdAt: widget.author?.createdAt,
      updatedAt: widget.author == null ? null : now,
    );

    try {
      if (widget.author == null) {
        await ref.read(authorRepositoryProvider).createAuthor(author);
      } else {
        await ref.read(authorRepositoryProvider).updateAuthor(author);
      }

      ref.invalidate(authorListProvider);
      if (widget.author != null) {
        ref.invalidate(authorDetailProvider(widget.author!.id));
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể lưu tác giả: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.author != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(
          isEditing ? 'Sửa thông tin tác giả' : 'Thêm tác giả',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildLabel('Tên tác giả *'),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  'Nhập tên tác giả',
                  Icons.person_outline,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên tác giả.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              _buildLabel('Ngày sinh'),
              InkWell(
                onTap: _selectBirthDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: _inputDecoration(
                    'Chọn ngày sinh',
                    Icons.calendar_month,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _birthDate == null
                              ? 'Chưa chọn ngày sinh'
                              : _formatDate(_birthDate!),
                          style: TextStyle(
                            color: _birthDate == null
                                ? Colors.grey
                                : Colors.black87,
                          ),
                        ),
                      ),
                      if (_birthDate != null)
                        IconButton(
                          tooltip: 'Xóa ngày sinh',
                          onPressed: () {
                            setState(() => _birthDate = null);
                          },
                          icon: const Icon(Icons.close),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _buildLabel('Quốc gia'),
              TextFormField(
                controller: _countryController,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  'Nhập quốc gia',
                  Icons.public,
                ),
              ),
              const SizedBox(height: 18),
              _buildLabel('Tiểu sử'),
              TextFormField(
                controller: _bioController,
                maxLines: 4,
                decoration: _inputDecoration(
                  'Nhập tiểu sử tác giả',
                  Icons.description_outlined,
                ),
              ),
              const SizedBox(height: 18),
              _buildLabel('Trạng thái'),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: _inputDecoration(
                  'Chọn trạng thái',
                  Icons.toggle_on_outlined,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'ACTIVE',
                    child: Text('ACTIVE'),
                  ),
                  DropdownMenuItem(
                    value: 'INACTIVE',
                    child: Text('INACTIVE'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _status = value);
                  }
                },
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveAuthor,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _isSaving
                        ? 'Đang lưu...'
                        : (isEditing ? 'Cập nhật' : 'Lưu tác giả'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE6EAF0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE6EAF0)),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
