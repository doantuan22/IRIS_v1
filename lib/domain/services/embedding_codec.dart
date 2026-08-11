import 'dart:typed_data';

/// Chuyển đổi vector embedding (`List<double>`) sang/từ BLOB để lưu trong
/// cột `embedding` của `profile_chunks` / `expert_knowledge_chunks`, đúng
/// quy ước ở roadmap mục 4: "bytes của Float32List đã serialize".
///
/// Ghi/đọc từng float32 tường minh theo Endian.little (thay vì dùng
/// `Float32List.buffer` trực tiếp) để tránh phụ thuộc byte order của máy
/// và vấn đề alignment khi bytes đọc về từ sqflite là 1 view lệch offset.
Uint8List encodeEmbedding(List<double> vector) {
  final byteData = ByteData(vector.length * 4);
  for (var i = 0; i < vector.length; i++) {
    byteData.setFloat32(i * 4, vector[i], Endian.little);
  }
  return byteData.buffer.asUint8List();
}

List<double> decodeEmbedding(Uint8List bytes) {
  final byteData = ByteData.sublistView(bytes);
  final length = bytes.lengthInBytes ~/ 4;
  return List<double>.generate(
    length,
    (i) => byteData.getFloat32(i * 4, Endian.little),
  );
}
