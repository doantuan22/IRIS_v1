class ScreeningResponse {
  final String id;
  final String screeningId;
  final String cauHoiId;
  final String linhVuc;
  final String giaTri; // '0' | '1' | '2' | 'N/A'
  final DateTime createdAt;

  const ScreeningResponse({
    required this.id,
    required this.screeningId,
    required this.cauHoiId,
    required this.linhVuc,
    required this.giaTri,
    required this.createdAt,
  });
}
