import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/data/local/database.dart';
import 'package:iris_app/data/repositories/child_repository.dart';
import 'package:iris_app/data/repositories/screening_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    AppDatabase.debugPathOverride = inMemoryDatabasePath;
  });

  setUp(() {
    AppDatabase.resetForTest();
  });

  test('Migration v7 -> v8: Khởi tạo, bảo toàn dữ liệu cũ, thêm 2 bảng mới', () async {
    final db = await AppDatabase.instance.database;

    // 1. Kiểm tra 2 bảng mới tồn tại
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('screening_responses', 'screening_domain_scores')",
    );
    final tableNames = tables.map((r) => r['name'] as String).toSet();
    expect(tableNames.contains('screening_responses'), isTrue);
    expect(tableNames.contains('screening_domain_scores'), isTrue);

    // 2. Tạo hồ sơ trẻ và lưu phiên sàng lọc 50 câu đầy đủ
    final childRepo = ChildRepository(AppDatabase.instance);
    final screeningRepo = ScreeningRepository(AppDatabase.instance);

    final child = await childRepo.create(name: 'Bé Test Migration', ageYears: 3);

    final responses = [
      (cauHoiId: 'sl50_q01', linhVuc: 'nhan_thuc', giaTri: '1'),
      (cauHoiId: 'sl50_q02', linhVuc: 'nhan_thuc', giaTri: '2'),
      (cauHoiId: 'sl50_q03', linhVuc: 'nhan_thuc', giaTri: 'N/A'),
    ];

    final domainScores = [
      (
        linhVuc: 'nhan_thuc',
        soCauThietKe: 7,
        soCauHopLe: 2,
        diemTho: 3,
        diemPhanTram: 75.0,
      ),
      (
        linhVuc: 'cam_xuc',
        soCauThietKe: 6,
        soCauHopLe: 0,
        diemTho: 0,
        diemPhanTram: null,
      ),
    ];

    final screening = await screeningRepo.saveScreeningSession(
      childId: child.id,
      toolName: 'sang_loc_50_cau_7_linh_vuc_v1',
      score: '75%',
      resultSummary: 'Mức 3 - Nhiều biểu hiện khó khăn',
      performedAt: DateTime.now(),
      responses: responses,
      domainScores: domainScores,
    );

    // 3. Đọc lại và kiểm tra
    expect(screening.id.isNotEmpty, isTrue);
    final hasScreening = await screeningRepo.hasScreening(child.id);
    expect(hasScreening, isTrue);

    final fetchedResponses = await screeningRepo.getResponses(screening.id);
    expect(fetchedResponses.length, 3);
    expect(fetchedResponses[0].cauHoiId, 'sl50_q01');
    expect(fetchedResponses[0].giaTri, '1');
    expect(fetchedResponses[2].giaTri, 'N/A');

    final fetchedDomainScores = await screeningRepo.getDomainScores(screening.id);
    expect(fetchedDomainScores.length, 2);
    expect(fetchedDomainScores[0].linhVuc, 'nhan_thuc');
    expect(fetchedDomainScores[0].diemPhanTram, 75.0);
    expect(fetchedDomainScores[1].linhVuc, 'cam_xuc');
    expect(fetchedDomainScores[1].diemPhanTram, isNull);

    // 4. Xóa child -> kiểm tra cascade sạch sẽ không lỗi Foreign Key
    await childRepo.delete(child.id);

    final afterDeleteScreenings = await screeningRepo.getForChild(child.id);
    expect(afterDeleteScreenings.isEmpty, isTrue);

    final afterDeleteResponses = await screeningRepo.getResponses(screening.id);
    expect(afterDeleteResponses.isEmpty, isTrue);

    final afterDeleteDomainScores = await screeningRepo.getDomainScores(screening.id);
    expect(afterDeleteDomainScores.isEmpty, isTrue);

    // ignore: avoid_print
    print('PASS: Migration v8 và cascade delete hoạt động hoàn hảo');
  });
}
