import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/data/local/tables/expert_knowledge_chunks_table.dart';
import 'package:iris_app/domain/services/embedding_codec.dart';
import 'package:iris_app/domain/services/expert_knowledge_seed_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// AssetBundle giả — kiểm soát chính xác nội dung file seed, không phụ
/// thuộc 532 entry thật trong repo (dễ đổi theo thời gian mỗi khi văn phong
/// được sửa tiếp).
class _FakeSeedBundle extends AssetBundle {
  final String jsonString;
  _FakeSeedBundle(this.jsonString);

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key == ExpertKnowledgeSeedService.seedAssetPath) return jsonString;
    throw FlutterError('Unable to load asset: "$key".');
  }

  @override
  Future<ByteData> load(String key) => throw UnimplementedError();
}

Map<String, dynamic> _seedEntry(
  String id, {
  String content = 'Nội dung mẫu',
  String linhVuc = 'nhan_thuc',
  String phanLoai = 'binh_thuong',
  int min = 15,
  int max = 23,
  List<double>? embedding,
}) {
  final vec = embedding ?? [0.1, 0.2, 0.3];
  return {
    'id': id,
    'content': content,
    'content_type': 'so_sanh',
    'linh_vuc': linhVuc,
    'phan_loai': phanLoai,
    'do_tuoi_thang_min': min,
    'do_tuoi_thang_max': max,
    'nguon_tai_lieu': null,
    'embedding_base64': base64Encode(encodeEmbedding(vec)),
  };
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) => db.execute(expertKnowledgeChunksTableCreate),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('seedIfEmpty: bảng rỗng -> insert đủ số dòng, giữ NGUYÊN id gốc (không sinh UUID)', () async {
    final seedJson = jsonEncode([
      _seedEntry('so_sanh_nhan_thuc_binh_thuong_15_23_001'),
      _seedEntry('so_sanh_cam_xuc_roi_loan_pho_tu_ky_24_47_002', linhVuc: 'cam_xuc', phanLoai: 'roi_loan_pho_tu_ky', min: 24, max: 47),
    ]);

    await ExpertKnowledgeSeedService.seedIfEmpty(db, bundle: _FakeSeedBundle(seedJson));

    final rows = await db.query('expert_knowledge_chunks');
    expect(rows.length, 2);
    final ids = rows.map((r) => r['id']).toSet();
    expect(
      ids,
      {'so_sanh_nhan_thuc_binh_thuong_15_23_001', 'so_sanh_cam_xuc_roi_loan_pho_tu_ky_24_47_002'},
      reason: 'id trong DB phải khớp CHÍNH XÁC id gốc trong seed — không phải UUID',
    );

    // ignore: avoid_print
    print('PASS: seedIfEmpty insert đúng dữ liệu, giữ nguyên id gốc');
  });

  test('seedIfEmpty: bảng ĐÃ có dữ liệu so_sanh -> KHÔNG seed lại, không nhân đôi', () async {
    await db.insert('expert_knowledge_chunks', {
      'id': 'existing-id',
      'content': 'Đã có sẵn',
      'content_type': 'so_sanh',
      'embedding': encodeEmbedding([0.1]),
    });

    final seedJson = jsonEncode([_seedEntry('so_sanh_nhan_thuc_binh_thuong_15_23_001')]);
    await ExpertKnowledgeSeedService.seedIfEmpty(db, bundle: _FakeSeedBundle(seedJson));

    final rows = await db.query('expert_knowledge_chunks');
    expect(rows.length, 1);
    expect(rows.single['id'], 'existing-id');

    // ignore: avoid_print
    print('PASS: bảng đã có dữ liệu -> seedIfEmpty không đụng gì, không nhân đôi');
  });

  test('seedIfEmpty: không có content_type khác so_sanh vẫn seed đúng (chỉ đếm so_sanh)', () async {
    await db.insert('expert_knowledge_chunks', {
      'id': 'other-type',
      'content': 'Loại khác',
      'content_type': 'khong_phai_so_sanh',
      'embedding': encodeEmbedding([0.1]),
    });

    final seedJson = jsonEncode([_seedEntry('so_sanh_nhan_thuc_binh_thuong_15_23_001')]);
    await ExpertKnowledgeSeedService.seedIfEmpty(db, bundle: _FakeSeedBundle(seedJson));

    final rows = await db.query('expert_knowledge_chunks');
    expect(rows.length, 2, reason: 'đếm rỗng chỉ tính content_type=so_sanh, không bị cản bởi loại khác');

    // ignore: avoid_print
    print('PASS: đếm rỗng chỉ theo content_type=so_sanh, seed đúng dù bảng đã có loại khác');
  });

  test('seedIfEmpty: an toàn khi asset chưa tồn tại (KHÔNG crash, bỏ qua)', () async {
    final missingBundle = _FakeSeedBundle('');
    // Ghi đè để loadString luôn throw (mô phỏng asset chưa tồn tại).
    await ExpertKnowledgeSeedService.seedIfEmpty(db, bundle: _MissingAssetBundle());

    final rows = await db.query('expert_knowledge_chunks');
    expect(rows, isEmpty);

    // ignore: avoid_print
    print('PASS: asset seed chưa tồn tại -> không crash, không insert gì, bỏ qua êm');
    // tránh unused warning
    expect(missingBundle, isNotNull);
  });

  test('resetAndReseed: xoá sạch so_sanh cũ rồi nạp lại đúng dữ liệu mới, GIỮ NGUYÊN dữ liệu content_type khác', () async {
    await db.insert('expert_knowledge_chunks', {
      'id': 'old-so-sanh-1',
      'content': 'So sánh cũ',
      'content_type': 'so_sanh',
      'embedding': encodeEmbedding([0.1]),
    });
    await db.insert('expert_knowledge_chunks', {
      'id': 'other-type-1',
      'content': 'Không phải so sánh',
      'content_type': 'khong_phai_so_sanh',
      'embedding': encodeEmbedding([0.1]),
    });

    final seedJson = jsonEncode([
      _seedEntry('so_sanh_nhan_thuc_binh_thuong_15_23_001', content: 'Nội dung MỚI'),
    ]);
    final total = await ExpertKnowledgeSeedService.resetAndReseed(db, bundle: _FakeSeedBundle(seedJson));

    expect(total, 1);
    final rows = await db.query('expert_knowledge_chunks');
    expect(rows.length, 2, reason: '1 dòng so_sanh mới + 1 dòng content_type khác được giữ nguyên');

    final soSanhRows = rows.where((r) => r['content_type'] == 'so_sanh').toList();
    expect(soSanhRows.length, 1);
    expect(soSanhRows.single['id'], 'so_sanh_nhan_thuc_binh_thuong_15_23_001');
    expect(soSanhRows.single['content'], 'Nội dung MỚI');

    final otherRows = rows.where((r) => r['content_type'] == 'khong_phai_so_sanh').toList();
    expect(otherRows.length, 1);
    expect(otherRows.single['id'], 'other-type-1');

    // ignore: avoid_print
    print('PASS: resetAndReseed xoá đúng so_sanh cũ, nạp đúng dữ liệu mới, không đụng content_type khác');
  });

  test('resetAndReseed: gọi 2 LẦN LIÊN TIẾP -> vẫn đúng số dòng, KHÔNG nhân đôi (idempotent)', () async {
    final seedJson = jsonEncode([
      _seedEntry('so_sanh_nhan_thuc_binh_thuong_15_23_001'),
      _seedEntry('so_sanh_cam_xuc_binh_thuong_15_23_002', linhVuc: 'cam_xuc'),
      _seedEntry('so_sanh_ngon_ngu_roi_loan_pho_tu_ky_48_60_003', linhVuc: 'ngon_ngu', phanLoai: 'roi_loan_pho_tu_ky', min: 48, max: 60),
    ]);

    final first = await ExpertKnowledgeSeedService.resetAndReseed(db, bundle: _FakeSeedBundle(seedJson));
    final rowsAfterFirst = await db.query('expert_knowledge_chunks');
    expect(first, 3);
    expect(rowsAfterFirst.length, 3);

    final second = await ExpertKnowledgeSeedService.resetAndReseed(db, bundle: _FakeSeedBundle(seedJson));
    final rowsAfterSecond = await db.query('expert_knowledge_chunks');
    expect(second, 3);
    expect(rowsAfterSecond.length, 3, reason: 'gọi lần 2 KHÔNG được nhân đôi thành 6 dòng');

    final ids = rowsAfterSecond.map((r) => r['id']).toSet();
    expect(ids.length, 3, reason: 'không trùng lặp id nào sau 2 lần reset');

    // ignore: avoid_print
    print('PASS: resetAndReseed idempotent — bấm 2 lần liên tiếp vẫn đúng 3 dòng, không nhân đôi');
  });

  test('embedding giải mã lại đúng giá trị gốc (đúng format encodeEmbedding/decodeEmbedding)', () async {
    final originalVector = [0.1, -0.25, 3.75, 0.0, -1.0];
    final seedJson = jsonEncode([
      _seedEntry('so_sanh_nhan_thuc_binh_thuong_15_23_001', embedding: originalVector),
    ]);

    await ExpertKnowledgeSeedService.seedIfEmpty(db, bundle: _FakeSeedBundle(seedJson));

    final row = (await db.query('expert_knowledge_chunks')).single;
    final decoded = decodeEmbedding(row['embedding'] as Uint8List);

    expect(decoded.length, originalVector.length);
    for (var i = 0; i < originalVector.length; i++) {
      expect(decoded[i], closeTo(originalVector[i], 0.0001));
    }

    // ignore: avoid_print
    print('PASS: embedding từ seed (base64) giải mã lại đúng giá trị gốc qua decodeEmbedding()');
  });
}

class _MissingAssetBundle extends AssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    throw FlutterError('Unable to load asset: "$key".');
  }

  @override
  Future<ByteData> load(String key) => throw UnimplementedError();
}
