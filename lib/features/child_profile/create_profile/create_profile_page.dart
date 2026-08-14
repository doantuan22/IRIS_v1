import 'package:flutter/material.dart';

import '../../../data/local/database.dart';
import '../../../data/repositories/child_repository.dart';
import '../../../domain/services/active_child_service.dart';
import 'create_profile_summary_page.dart';

enum _AgeInputMode { dob, ageYears }

/// Bước 1-2 — Tạo hồ sơ trẻ: tên, ngày sinh HOẶC số tuổi, giới tính.
class CreateProfilePage extends StatefulWidget {
  const CreateProfilePage({super.key});

  @override
  State<CreateProfilePage> createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends State<CreateProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageYearsController = TextEditingController();
  final _nguoiDanhGiaController = TextEditingController();

  final _childRepository = ChildRepository(AppDatabase.instance);
  final _activeChildService = ActiveChildService();

  _AgeInputMode _ageInputMode = _AgeInputMode.dob;
  DateTime? _selectedDob;
  String? _gender;
  String? _vaiTro;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageYearsController.dispose();
    _nguoiDanhGiaController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 2, now.month, now.day),
      firstDate: DateTime(now.year - 18),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _selectedDob = picked);
    }
  }

  String? _validateAgeInput() {
    if (_ageInputMode == _AgeInputMode.dob) {
      return _selectedDob == null ? 'Vui lòng chọn ngày sinh' : null;
    }
    final text = _ageYearsController.text.trim();
    if (text.isEmpty) return 'Vui lòng nhập số tuổi';
    final years = int.tryParse(text);
    if (years == null || years < 0 || years > 18) return 'Số tuổi không hợp lệ';
    return null;
  }

  Future<void> _submit() async {
    final ageError = _validateAgeInput();
    if (!(_formKey.currentState?.validate() ?? false) || ageError != null) {
      if (ageError != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ageError)));
      }
      return;
    }

    setState(() => _saving = true);
    try {
      final created = await _childRepository.create(
        name: _nameController.text.trim(),
        dob: _ageInputMode == _AgeInputMode.dob ? _selectedDob?.toIso8601String() : null,
        ageYears: _ageInputMode == _AgeInputMode.ageYears
            ? int.parse(_ageYearsController.text.trim())
            : null,
        gender: _gender,
        nguoiDanhGia: _nguoiDanhGiaController.text.trim().isEmpty
            ? null
            : _nguoiDanhGiaController.text.trim(),
        vaiTro: _vaiTro,
      );
      // Hồ sơ vừa tạo luôn trở thành "hồ sơ đang hoạt động" — áp dụng thống
      // nhất cho mọi lối vào (tạo hồ sơ đầu tiên khi mở app lần đầu, hoặc
      // tạo thêm hồ sơ mới từ tab "Tài khoản"), không phân biệt ngữ cảnh gọi.
      await _activeChildService.setActiveChildId(created.id);
      if (mounted) {
        // `result: true` báo ngay cho màn gọi (VD ChildListPage) làm mới danh
        // sách trong lúc người dùng đang xem màn tóm tắt — không đợi họ bấm
        // quay lại hết ngăn xếp mới refresh.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => CreateProfileSummaryPage(child: created)),
          result: true,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo hồ sơ mới')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Tên trẻ *'),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Vui lòng nhập tên' : null,
            ),
            const SizedBox(height: 16),
            const Text('Cách nhập tuổi *', style: TextStyle(fontWeight: FontWeight.bold)),
            RadioGroup<_AgeInputMode>(
              groupValue: _ageInputMode,
              onChanged: (mode) => setState(() => _ageInputMode = mode!),
              child: Column(
                children: [
                  const RadioListTile<_AgeInputMode>(
                    title: Text('Theo ngày sinh'),
                    value: _AgeInputMode.dob,
                  ),
                  if (_ageInputMode == _AgeInputMode.dob)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton(
                          onPressed: _pickDob,
                          child: Text(
                            _selectedDob == null
                                ? 'Chọn ngày sinh'
                                : '${_selectedDob!.day}/${_selectedDob!.month}/${_selectedDob!.year}',
                          ),
                        ),
                      ),
                    ),
                  const RadioListTile<_AgeInputMode>(
                    title: Text('Theo số tuổi (năm)'),
                    value: _AgeInputMode.ageYears,
                  ),
                  if (_ageInputMode == _AgeInputMode.ageYears)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 8),
                      child: TextFormField(
                        controller: _ageYearsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Số tuổi'),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Giới tính', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              emptySelectionAllowed: true,
              segments: const [
                ButtonSegment(value: 'nam', label: Text('Nam')),
                ButtonSegment(value: 'nu', label: Text('Nữ')),
                ButtonSegment(value: 'khac', label: Text('Khác')),
              ],
              selected: _gender == null ? const {} : {_gender!},
              onSelectionChanged: (selection) =>
                  setState(() => _gender = selection.isEmpty ? null : selection.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nguoiDanhGiaController,
              decoration: const InputDecoration(labelText: 'Người đánh giá'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _vaiTro,
              decoration: const InputDecoration(labelText: 'Vai trò'),
              items: const [
                DropdownMenuItem(value: 'Phụ huynh', child: Text('Phụ huynh')),
                DropdownMenuItem(value: 'Giáo viên', child: Text('Giáo viên')),
                DropdownMenuItem(value: 'Chuyên viên', child: Text('Chuyên viên')),
              ],
              onChanged: (value) => setState(() => _vaiTro = value),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Lưu hồ sơ'),
            ),
          ],
        ),
      ),
    );
  }
}
