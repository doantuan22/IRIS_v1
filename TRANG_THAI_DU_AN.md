# Trạng thái dự án IRIS

## Audit toàn diện — 2026-08-16

**Kết luận hiện tại: chưa sẵn sàng demo hoặc phát hành release.**

### Trạng thái theo giai đoạn

| Giai đoạn | Kết quả |
|---|---|
| 1. Xác lập trạng thái | Hoàn tất trong phạm vi source/Git/assets. JSON có 532 entry (200/196/136), nhưng chưa query được DB app thực. |
| 2. Debug trên Pixel_7 | Chưa thực hiện: `adb devices -l` không có thiết bị/emulator. |
| 3. Release trên Pixel_7 | Chưa thực hiện: build mới không hoàn tất; không có thiết bị để cài thử. |

### Lỗi chặn cần ưu tiên

1. Release cài mới không seed `expert_knowledge_chunks`; So sánh rỗng vì nạp data chỉ có trong UI Debug.
2. Nạp Debug tạo UUID mới thay vì ID JSON, làm manifest video theo ID không thể khớp bản ghi DB; nút video không hiện.
3. 204 video asset hiện chiếm 1,755.39 MiB, khiến APK release dự kiến phình quá lớn.

### Rủi ro phát hành

- 137 thay đổi chưa commit (3 modified, 134 untracked), bao gồm dữ liệu/video mới.
- Không có `android/key.properties`: release fallback sang debug signing, chưa phải cấu hình phát hành thật.
- APK cũ 24.58 MiB trong `build/` không chứa manifest/video/dữ liệu 48–60 mới; không phải bằng chứng release hiện hành.

Chi tiết bằng chứng, cách tái hiện và các mục chưa xác minh nằm trong `SETUP_REPORT.md`, mục “Audit toàn diện sau khi bổ sung 3 dải tuổi và video mẫu (2026-08-16)”.
