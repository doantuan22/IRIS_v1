import 'package:flutter/material.dart';

import '../../../core/constants/screening_domains.dart';
import '../../../data/local/database.dart';
import '../../../data/repositories/child_repository.dart';
import '../../../domain/models/child.dart';
import '../../../domain/services/active_child_service.dart';
import '../../screening/screening_intro_page.dart';

enum _AgeInputMode { dob, ageTier }

/// Bước 1-2 — Tạo hồ sơ trẻ: tên, ngày sinh HOẶC số tháng tuổi, giới tính.
class CreateProfilePage extends StatefulWidget {
  const CreateProfilePage({super.key});

  @override
  State<CreateProfilePage> createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends State<CreateProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nguoiDanhGiaController = TextEditingController();

  final _childRepository = ChildRepository(AppDatabase.instance);
  final _activeChildService = ActiveChildService();

  _AgeInputMode _ageInputMode = _AgeInputMode.dob;
  DateTime? _selectedDob;
  String? _selectedAgeTier;
  String? _gender;
  String? _vaiTro;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
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
    return _selectedAgeTier == null ? 'Vui lòng chọn 1 mức tuổi' : null;
  }

  Future<void> _submit() async {
    final ageError = _validateAgeInput();
    if (!(_formKey.currentState?.validate() ?? false) || ageError != null) {
      if (ageError != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ageError)));
      }
      return;
    }

    setState(() => _saving = true);
    try {
      // Khi chọn trực tiếp 1 mức tuổi (không có ngày sinh), quy đổi thành
      // `dob` gần đúng bằng THÁNG ĐẠI DIỆN giữa dải mỗi mức
      // (`ScreeningAgeTierRange.representativeMonths`) — GIẢ ĐỊNH LÀM VIỆC
      // của dự án, CẦN CHUYÊN GIA XÁC NHẬN LẠI trước khi dùng chính thức
      // (chưa phải thang đo lâm sàng đã kiểm định). `childAgeInMonths()`
      // dùng cho phần Đánh giá 7 lĩnh vực đọc `dob` như bình thường, không
      // bị ảnh hưởng bởi cách quy đổi này.
      final dob = _ageInputMode == _AgeInputMode.dob
          ? _selectedDob
          : dobFromAgeInMonths(
              screeningAgeTierRanges
                  .firstWhere((r) => r.tier == _selectedAgeTier)
                  .representativeMonths,
            );

      final created = await _childRepository.create(
        name: _nameController.text.trim(),
        dob: dob?.toIso8601String(),
        ageYears: null, // Hồ sơ mới luôn dùng dob, không lưu ageYears
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
        // Vào thẳng màn hỏi sàng lọc (Bước 3) thay vì màn chi tiết hồ sơ —
        // `pushReplacement` để người dùng không back được về form tạo hồ sơ
        // đã nộp. `result: true` báo ngay cho màn gọi (VD
        // MultiChildDashboardPage) làm mới danh sách trong lúc người dùng
        // tiếp tục luồng sàng lọc — không đợi họ quay lại hết ngăn xếp.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                ScreeningIntroPage(child: created, isOnboarding: true),
          ),
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
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Vui lòng nhập tên'
                  : null,
            ),
            const SizedBox(height: 16),
            const Text(
              'Cách nhập tuổi *',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
                    title: Text('Chọn theo độ tuổi'),
                    value: _AgeInputMode.ageTier,
                  ),
                  if (_ageInputMode == _AgeInputMode.ageTier)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            children: screeningAgeTierRanges.map((range) {
                              return ChoiceChip(
                                label: Text(screeningAgeTierLabel(range.tier)),
                                selected: _selectedAgeTier == range.tier,
                                onSelected: (_) => setState(
                                  () => _selectedAgeTier = range.tier,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Giới tính',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              emptySelectionAllowed: true,
              segments: const [
                ButtonSegment(value: 'nam', label: Text('Nam')),
                ButtonSegment(value: 'nu', label: Text('Nữ')),
                ButtonSegment(value: 'khac', label: Text('Khác')),
              ],
              selected: _gender == null ? const {} : {_gender!},
              onSelectionChanged: (selection) => setState(
                () => _gender = selection.isEmpty ? null : selection.first,
              ),
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
                DropdownMenuItem(
                  value: 'Chuyên viên',
                  child: Text('Chuyên viên'),
                ),
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
