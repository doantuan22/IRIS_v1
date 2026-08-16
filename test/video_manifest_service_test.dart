import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris_app/domain/services/video_manifest_service.dart';

/// AssetBundle giả — kiểm soát chính xác nội dung `video_manifest.json` trả
/// về, không phụ thuộc dữ liệu thật trong repo (78 video thật có thể đổi
/// theo thời gian, làm test dễ vỡ nếu dựa vào số liệu đó).
class _FakeBundle extends AssetBundle {
  final Map<String, String> _files;
  int loadCallCount = 0;

  _FakeBundle(this._files);

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    loadCallCount++;
    if (_files.containsKey(key)) return _files[key]!;
    throw FlutterError('Unable to load asset: "$key".');
  }

  @override
  Future<ByteData> load(String key) => throw UnimplementedError();
}

void main() {
  setUp(() {
    VideoManifestService.clearCache();
  });

  test('parseJson đọc đúng schema {"videos": {"<id>": {"file_path": ...}}}', () {
    final json = jsonEncode({
      'videos': {
        'so_sanh_nhan_thuc_binh_thuong_15_23_001': {
          'file_path': 'assets/videos/nhan_thuc/so_sanh_nhan_thuc_binh_thuong_15_23_001.mp4',
          'ten_file_goc': 'clip.mp4',
          'ngay_them': '2026-08-16T10:00:00',
        },
        'so_sanh_cam_xuc_binh_thuong_15_23_001': {
          'file_path': 'assets/videos/cam_xuc/so_sanh_cam_xuc_binh_thuong_15_23_001.mp4',
          'ten_file_goc': 'clip2.mp4',
          'ngay_them': '2026-08-16T10:01:00',
        },
      },
    });

    final result = VideoManifestService.parseJson(json);

    expect(result.length, 2);
    expect(
      result['so_sanh_nhan_thuc_binh_thuong_15_23_001'],
      'assets/videos/nhan_thuc/so_sanh_nhan_thuc_binh_thuong_15_23_001.mp4',
    );
    // ignore: avoid_print
    print('PASS: parseJson đọc đúng id -> file_path');
  });

  test('parseJson trả rỗng nếu thiếu field "videos"', () {
    final result = VideoManifestService.parseJson(jsonEncode({}));
    expect(result, isEmpty);
    // ignore: avoid_print
    print('PASS: thiếu field "videos" -> rỗng, không lỗi');
  });

  testWidgets('loadVideoPaths đọc đúng dữ liệu từ bundle + cache lại, không đọc lại lần 2', (tester) async {
    final bundle = _FakeBundle({
      VideoManifestService.assetPath: jsonEncode({
        'videos': {
          'entry-1': {'file_path': 'assets/videos/nhan_thuc/entry-1.mp4', 'ten_file_goc': 'x', 'ngay_them': 'x'},
        },
      }),
    });

    final first = await VideoManifestService.loadVideoPaths(bundle: bundle);
    expect(first['entry-1'], 'assets/videos/nhan_thuc/entry-1.mp4');
    expect(bundle.loadCallCount, 1);

    final second = await VideoManifestService.loadVideoPaths(bundle: bundle);
    expect(second, first);
    expect(bundle.loadCallCount, 1, reason: 'lần gọi thứ 2 phải dùng cache, KHÔNG đọc lại file');

    // ignore: avoid_print
    print('PASS: loadVideoPaths cache đúng, chỉ đọc file 1 lần dù gọi nhiều lần');
  });

  testWidgets('getVideoPathForId trả đúng path sau khi đã nạp, null cho id không có video', (tester) async {
    final bundle = _FakeBundle({
      VideoManifestService.assetPath: jsonEncode({
        'videos': {
          'has-video': {'file_path': 'assets/videos/nhan_thuc/has-video.mp4', 'ten_file_goc': 'x', 'ngay_them': 'x'},
        },
      }),
    });
    await VideoManifestService.loadVideoPaths(bundle: bundle);

    expect(VideoManifestService.getVideoPathForId('has-video'), 'assets/videos/nhan_thuc/has-video.mp4');
    expect(VideoManifestService.getVideoPathForId('khong-co-video'), isNull);

    // ignore: avoid_print
    print('PASS: getVideoPathForId đúng cho cả 2 trường hợp có/không có video');
  });

  testWidgets('loadVideoPaths an toàn khi asset chưa tồn tại (chưa gắn video nào) — trả rỗng, không lỗi', (tester) async {
    final bundle = _FakeBundle({}); // không có key nào -> loadString ném lỗi

    final result = await VideoManifestService.loadVideoPaths(bundle: bundle);

    expect(result, isEmpty);
    expect(VideoManifestService.getVideoPathForId('bat-ky-id-nao'), isNull);

    // ignore: avoid_print
    print('PASS: manifest chưa tồn tại (VD dải tuổi 24-47/48-60 chưa gắn video) -> rỗng, không crash');
  });

  test('clearCache buộc lần gọi sau đọc lại từ bundle', () async {
    final bundle1 = _FakeBundle({
      VideoManifestService.assetPath: jsonEncode({
        'videos': {'a': {'file_path': 'assets/videos/nhan_thuc/a.mp4', 'ten_file_goc': 'x', 'ngay_them': 'x'}},
      }),
    });
    await VideoManifestService.loadVideoPaths(bundle: bundle1);
    expect(VideoManifestService.getVideoPathForId('a'), isNotNull);

    VideoManifestService.clearCache();

    final bundle2 = _FakeBundle({
      VideoManifestService.assetPath: jsonEncode({'videos': <String, dynamic>{}}),
    });
    await VideoManifestService.loadVideoPaths(bundle: bundle2);
    expect(VideoManifestService.getVideoPathForId('a'), isNull, reason: 'sau clearCache phải đọc lại từ bundle mới, không còn giữ dữ liệu cũ');

    // ignore: avoid_print
    print('PASS: clearCache xoá đúng cache, lần gọi sau đọc lại từ bundle mới');
  });
}
