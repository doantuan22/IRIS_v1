/// Model video quay tình huống, ánh xạ tới bảng `videos`. Video lưu file
/// local qua `path_provider`; model này chỉ giữ metadata + đường dẫn.
/// [status]: 'not_sent' (mới quay) / 'pending' (đã gửi, chờ chuyên gia) /
/// 'reviewed' (đã có nhận xét).
class Video {
  final String id;
  final String childId;
  final String? situation;
  final String filePath;
  final String status;
  final String? expertNote;
  final DateTime recordedAt;

  const Video({
    required this.id,
    required this.childId,
    this.situation,
    required this.filePath,
    this.status = 'not_sent',
    this.expertNote,
    required this.recordedAt,
  });
}
