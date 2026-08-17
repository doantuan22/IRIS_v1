// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:iris_app/domain/services/embedding_codec.dart';

const String _nvidiaEmbeddingEndpoint =
    'https://integrate.api.nvidia.com/v1/embeddings';
const String _nvidiaEmbeddingModel = 'nvidia/nv-embedqa-e5-v5';
const int _batchSize = 20;

const List<String> _sourceFiles = [
  'assets/reference/so_sanh_15_23_thang.json',
  'assets/reference/so_sanh_24_47_thang.json',
  'assets/reference/so_sanh_48_60_thang.json',
];

const String _outputPath = 'assets/reference/expert_knowledge_seed.json';

/// Sinh file seed `expert_knowledge_seed.json` — đọc 3 file
/// `so_sanh_*_thang.json` (bản đã sửa văn phong mới nhất), gọi NVIDIA
/// embedding API (batch 20 entry/request), GIỮ NGUYÊN `id` gốc từ JSON, ghi
/// ra 1 file JSON duy nhất chứa sẵn embedding (base64 của đúng bytes
/// `encodeEmbedding()` — cùng format app dùng để lưu BLOB) để app tự seed
/// vào SQLite lúc chạy, KHÔNG cần gọi API nữa.
///
/// Chạy 1 lần (mỗi khi 3 file so_sanh_*_thang.json bị sửa nội dung), cần
/// NVIDIA_API_KEY thật (đọc từ `dart_define.json` hoặc biến môi trường —
/// KHÔNG BAO GIỜ in giá trị key ra log):
///   dart run scripts/generate_expert_knowledge_seed.dart
void main() async {
  print('=== SINH FILE SEED expert_knowledge_seed.json ===');

  var apiKey = Platform.environment['NVIDIA_API_KEY'] ?? '';
  if (apiKey.isEmpty) {
    final defineFile = File('dart_define.json');
    if (defineFile.existsSync()) {
      try {
        final map = jsonDecode(defineFile.readAsStringSync()) as Map<String, dynamic>;
        apiKey = (map['NVIDIA_API_KEY'] as String?) ?? '';
      } catch (_) {}
    }
  }
  if (apiKey.isEmpty) {
    print('LỖI: Chưa có NVIDIA_API_KEY (dart_define.json hoặc biến môi trường).');
    exit(1);
  }

  final entries = <Map<String, dynamic>>[];
  final seenIds = <String>{};
  for (final path in _sourceFiles) {
    final file = File(path);
    if (!file.existsSync()) {
      print('LỖI: Không tìm thấy $path — chạy script từ thư mục gốc repo.');
      exit(1);
    }
    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final fileEntries = (data['entries'] as List<dynamic>).cast<Map<String, dynamic>>();
    for (final e in fileEntries) {
      final id = e['id'] as String;
      if (!seenIds.add(id)) {
        print('LỖI: id trùng lặp giữa các file: $id');
        exit(1);
      }
      entries.add(e);
    }
    print('Đọc $path: ${fileEntries.length} entry.');
  }
  print('Tổng cộng ${entries.length} entry cần tính embedding.\n');

  final client = http.Client();
  final results = <Map<String, dynamic>>[];
  final failedIds = <String>[];

  for (var i = 0; i < entries.length; i += _batchSize) {
    final end = (i + _batchSize < entries.length) ? i + _batchSize : entries.length;
    final batch = entries.sublist(i, end);
    final texts = batch.map((e) => e['content'] as String).toList();

    var attempt = 0;
    const maxAttempts = 3;
    while (true) {
      attempt++;
      try {
        final response = await client
            .post(
              Uri.parse(_nvidiaEmbeddingEndpoint),
              headers: {
                'Authorization': 'Bearer $apiKey',
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode({
                'input': texts,
                'model': _nvidiaEmbeddingModel,
                'input_type': 'query',
                'encoding_format': 'float',
              }),
            )
            .timeout(const Duration(seconds: 30));

        if (response.statusCode != 200) {
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }

        final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final responseData = (decoded['data'] as List).cast<Map<String, dynamic>>();
        if (responseData.length != batch.length) {
          throw Exception(
            'Số embedding trả về (${responseData.length}) khác số entry gửi đi (${batch.length})',
          );
        }
        // Map theo "index" trả về, không giả định thứ tự response == thứ tự gửi.
        final byIndex = {for (final d in responseData) d['index'] as int: d};

        for (var j = 0; j < batch.length; j++) {
          final entry = batch[j];
          final item = byIndex[j];
          if (item == null) {
            throw Exception('Thiếu embedding cho vị trí $j trong batch (id: ${entry['id']})');
          }
          final embedding = (item['embedding'] as List).map((v) => (v as num).toDouble()).toList();
          final embeddingBase64 = base64Encode(encodeEmbedding(embedding));

          results.add({
            'id': entry['id'],
            'content': entry['content'],
            'content_type': entry['content_type'],
            'linh_vuc': entry['linh_vuc'],
            'phan_loai': entry['phan_loai'],
            'do_tuoi_thang_min': entry['do_tuoi_thang_min'],
            'do_tuoi_thang_max': entry['do_tuoi_thang_max'],
            'nguon_tai_lieu': entry['nguon_tai_lieu'],
            'embedding_base64': embeddingBase64,
          });
        }
        stdout.write('.');
        break;
      } catch (e) {
        if (attempt >= maxAttempts) {
          print('\nLỖI batch $i-$end sau $maxAttempts lần thử: $e');
          for (final entry in batch) {
            failedIds.add(entry['id'] as String);
          }
          break;
        }
        print('\nLỗi batch $i-$end (lần $attempt/$maxAttempts): $e — thử lại...');
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
  }
  client.close();
  print('');

  final outFile = File(_outputPath);
  outFile.writeAsStringSync(jsonEncode(results));

  print('\n=== HOÀN TẤT ===');
  print('Thành công: ${results.length}/${entries.length} entry.');
  if (failedIds.isNotEmpty) {
    print('LỖI — ${failedIds.length} id KHÔNG có embedding (cần chạy lại):');
    for (final id in failedIds) {
      print('  - $id');
    }
  }
  print('Đã ghi: $_outputPath');

  if (results.length != 532) {
    print('\nCẢNH BÁO: kỳ vọng 532 entry, thực tế ${results.length} — KIỂM TRA LẠI trước khi dùng file này.');
    exit(1);
  }
}
