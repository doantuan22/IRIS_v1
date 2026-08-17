import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

/// Seed dữ liệu tham khảo "So sánh" (content_type='so_sanh') vào
/// `expert_knowledge_chunks` từ file `assets/reference/expert_knowledge_seed.json`
/// — file này đã có sẵn EMBEDDING tính trước (script
/// `scripts/generate_expert_knowledge_seed.dart`, gọi NVIDIA API 1 lần lúc
/// biên soạn nội dung), nên seed lúc app chạy chỉ đọc file local + ghi
/// SQLite, KHÔNG gọi mạng, chạy nhanh, hoạt động ở MỌI bản build (kể cả
/// release — sửa BUG-01: trước đây dữ liệu "So sánh" chỉ vào được DB qua nút
/// debug, bị loại khỏi bản release do `kDebugMode`).
///
/// GIỮ NGUYÊN `id` gốc từ JSON (không sinh UUID mới) — sửa BUG-02: trước đây
/// `ExpertKnowledgeRepository.add()` luôn tự sinh UUID, khiến
/// `video_manifest.json` (khoá theo `id` gốc) không bao giờ khớp được với DB
/// thật, nút "Xem video minh hoạ" không hiện dù đã gắn video.
///
/// ============================================================================
/// QUY TRÌNH CHUẨN MỖI KHI SỬA NỘI DUNG 3 FILE `so_sanh_*_thang.json` SAU NÀY:
/// ============================================================================
/// 1. Sửa nội dung trong `assets/reference/so_sanh_{15_23,24_47,48_60}_thang.json`.
/// 2. Chạy lại `dart run scripts/generate_expert_knowledge_seed.dart` (cần
///    NVIDIA_API_KEY thật) để tính lại embedding và ghi đè
///    `assets/reference/expert_knowledge_seed.json`.
/// 3. Trên thiết bị/emulator đang chạy app: bấm nút debug "Reset & nạp lại dữ
///    liệu tham khảo" (hoặc gỡ cài đặt app rồi cài lại) để DB thật đồng bộ
///    lại theo file seed mới.
/// SỬA FILE JSON NGUỒN KHÔNG TỰ ĐỘNG ĐỒNG BỘ VÀO APP ĐANG CHẠY — đây là hành
/// vi THIẾT KẾ có chủ đích (seed chỉ chạy khi bảng rỗng, để không phải gọi
/// lại API embedding mỗi lần mở app), KHÔNG PHẢI BUG. Quên bước 2/3 ở trên là
/// nguyên nhân phổ biến nhất khiến "sửa JSON nhưng app vẫn hiện bản cũ".
/// ============================================================================
class ExpertKnowledgeSeedService {
  static const String seedAssetPath = 'assets/reference/expert_knowledge_seed.json';

  /// Seed nếu bảng đang RỖNG với content_type='so_sanh' — gọi từ `onOpen` của
  /// `AppDatabase` (chạy ở MỌI lần mở DB, không chỉ `onCreate`, để tự "chữa
  /// lành" cho cả người dùng nâng cấp từ bản cũ chưa từng có dữ liệu này,
  /// không chỉ cài mới). An toàn khi gọi nhiều lần — chỉ thực sự insert khi
  /// đếm được 0 dòng.
  ///
  /// NUỐT MỌI LỖI khi đọc asset (VD chạy trong test Dart VM thuần không có
  /// `TestWidgetsFlutterBinding`/asset channel thật, hoặc file seed chưa tồn
  /// tại) — đây là seed "best-effort" chạy nền lúc mở DB, KHÔNG được phép
  /// làm hỏng việc mở database của app vì bất kỳ lý do gì.
  static Future<void> seedIfEmpty(Database db, {AssetBundle? bundle}) async {
    try {
      final countResult = await db.rawQuery(
        "SELECT COUNT(*) as c FROM expert_knowledge_chunks WHERE content_type = 'so_sanh'",
      );
      final count = Sqflite.firstIntValue(countResult) ?? 0;
      if (count > 0) return;

      await _insertAllFromSeedFile(db, bundle: bundle);
    } catch (_) {
      // Best-effort: không seed được thì bỏ qua, không chặn app khởi động.
    }
  }

  /// Xoá sạch dữ liệu "So sánh" hiện có rồi nạp lại từ file seed — dùng cho
  /// nút debug "Reset & nạp lại dữ liệu tham khảo". Idempotent: bấm nhiều
  /// lần liên tiếp luôn cho đúng 532 dòng, KHÔNG nhân bản (khác hẳn nút debug
  /// cũ — mỗi lần bấm gọi API + insert thêm, nhân đôi/ba dữ liệu).
  static Future<int> resetAndReseed(Database db, {AssetBundle? bundle}) async {
    await db.delete('expert_knowledge_chunks', where: "content_type = 'so_sanh'");
    return _insertAllFromSeedFile(db, bundle: bundle);
  }

  static Future<int> _insertAllFromSeedFile(Database db, {AssetBundle? bundle}) async {
    final effectiveBundle = bundle ?? rootBundle;
    final jsonString = await effectiveBundle.loadString(seedAssetPath);
    final entries = (jsonDecode(jsonString) as List<dynamic>).cast<Map<String, dynamic>>();

    final batch = db.batch();
    for (final entry in entries) {
      batch.insert('expert_knowledge_chunks', {
        'id': entry['id'] as String,
        'content': entry['content'] as String,
        'content_type': entry['content_type'] as String,
        'phan_loai': entry['phan_loai'] as String?,
        'nhom_tre': null,
        'boi_canh': null,
        'linh_vuc': entry['linh_vuc'] as String?,
        'do_tuoi_thang_min': entry['do_tuoi_thang_min'] as int?,
        'do_tuoi_thang_max': entry['do_tuoi_thang_max'] as int?,
        'nguon_tai_lieu': entry['nguon_tai_lieu'] as String?,
        'embedding': base64Decode(entry['embedding_base64'] as String),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
    return entries.length;
  }
}
