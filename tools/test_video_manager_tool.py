"""Test logic thuần của video_manager_tool.py (mô hình video theo TỪNG ID
entry) — KHÔNG tạo cửa sổ GUI nào.

Import thẳng module (tkinter chỉ được import bên trong `_run_gui()`, không ở
top-level, nên import module này không đòi hỏi môi trường có màn hình/GUI
thật — chỉ cần tkinter cài sẵn trong Python, không cần `Tk()` chạy được).

Chạy: python tools/test_video_manager_tool.py
"""

from __future__ import annotations

import json
import shutil
import sys
import tempfile
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")

sys.path.insert(0, str(Path(__file__).parent))
import video_manager_tool as vm  # noqa: E402

PASS = "PASS"
FAIL = "FAIL"
_results: list[tuple[str, bool, str]] = []


def check(name: str, condition: bool, detail: str = "") -> None:
    _results.append((name, condition, detail))
    status = PASS if condition else FAIL
    print(f"[{status}] {name}" + (f" — {detail}" if detail and not condition else ""))


# ---------------------------------------------------------------------------
# Fixture: tạo 1 "dự án giả" với đúng cấu trúc assets/reference/so_sanh_*_thang.json.
# ---------------------------------------------------------------------------


def make_fake_so_sanh_file(project_root: Path, filename: str, min_m: int, max_m: int, entries: list[dict]) -> Path:
    path = project_root / "assets" / "reference" / filename
    path.parent.mkdir(parents=True, exist_ok=True)
    data = {
        "meta": {"do_tuoi_thang_min": min_m, "do_tuoi_thang_max": max_m, "tong_so_entry": len(entries)},
        "entries": entries,
    }
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    return path


def make_entry(id_suffix: str, linh_vuc: str, phan_loai: str, min_m: int, max_m: int, content: str) -> dict:
    entry_id = f"so_sanh_{linh_vuc}_{phan_loai}_{min_m}_{max_m}_{id_suffix}"
    return {
        "id": entry_id,
        "content_type": "so_sanh",
        "linh_vuc": linh_vuc,
        "phan_loai": phan_loai,
        "do_tuoi_thang_min": min_m,
        "do_tuoi_thang_max": max_m,
        "content": content,
        "nguon_tai_lieu": None,
    }


def make_fake_video(path: Path, content: bytes = b"fake video bytes") -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(content)
    return path


# ---------------------------------------------------------------------------
# Test: nạp entries từ nhiều file so_sanh_*_thang.json.
# ---------------------------------------------------------------------------


def test_find_and_load_all_entries(tmp: Path) -> None:
    project = tmp / "proj_load"
    make_fake_so_sanh_file(
        project, "so_sanh_15_23_thang.json", 15, 23,
        [
            make_entry("001", "nhan_thuc", "binh_thuong", 15, 23, "Nội dung A"),
            make_entry("001", "nhan_thuc", "roi_loan_pho_tu_ky", 15, 23, "Nội dung B"),
        ],
    )
    make_fake_so_sanh_file(
        project, "so_sanh_24_47_thang.json", 24, 47,
        [make_entry("001", "ngon_ngu", "binh_thuong", 24, 47, "Nội dung C")],
    )
    # File không khớp mẫu -> KHÔNG được đọc.
    (project / "assets" / "reference" / "expert_content.json").write_text("[]", encoding="utf-8")

    files = vm.find_so_sanh_files(project)
    check("tự dò đúng 2 file so_sanh_*_thang.json (bỏ qua file khác)", len(files) == 2)
    check(
        "kết quả glob sắp xếp ổn định (15_23 trước 24_47)",
        [f.name for f in files] == ["so_sanh_15_23_thang.json", "so_sanh_24_47_thang.json"],
    )

    entries, warnings = vm.load_all_entries(project)
    check("gộp đủ 3 entry từ 2 file", len(entries) == 3, detail=str(len(entries)))
    check("không có cảnh báo nào khi dữ liệu hợp lệ", warnings == [], detail=str(warnings))
    check(
        "mỗi entry được gắn đúng _source_file",
        {e["id"]: e["_source_file"] for e in entries} == {
            "so_sanh_nhan_thuc_binh_thuong_15_23_001": "so_sanh_15_23_thang.json",
            "so_sanh_nhan_thuc_roi_loan_pho_tu_ky_15_23_001": "so_sanh_15_23_thang.json",
            "so_sanh_ngon_ngu_binh_thuong_24_47_001": "so_sanh_24_47_thang.json",
        },
    )


def test_load_all_entries_handles_duplicate_and_malformed(tmp: Path) -> None:
    project = tmp / "proj_dup"
    make_fake_so_sanh_file(
        project, "so_sanh_15_23_thang.json", 15, 23,
        [make_entry("001", "cam_xuc", "binh_thuong", 15, 23, "Bản gốc")],
    )
    # File thứ 2 cố tình dùng TRÙNG id với file 1.
    dup_entry = make_entry("001", "cam_xuc", "binh_thuong", 15, 23, "Bản trùng — không nên được giữ")
    make_fake_so_sanh_file(project, "so_sanh_24_47_thang.json", 24, 47, [dup_entry])

    entries, warnings = vm.load_all_entries(project)
    check("id trùng chỉ giữ 1 bản (bản xuất hiện trước)", len(entries) == 1)
    check("giữ đúng bản GỐC khi trùng id", entries[0]["content"] == "Bản gốc")
    check("có cảnh báo rõ ràng về id trùng lặp", any("trùng lặp" in w for w in warnings), detail=str(warnings))


def test_load_all_entries_missing_dir(tmp: Path) -> None:
    project = tmp / "proj_empty"
    project.mkdir()
    entries, warnings = vm.load_all_entries(project)
    check("thư mục assets/reference/ chưa tồn tại -> trả về rỗng, không lỗi", entries == [] and warnings == [])


# ---------------------------------------------------------------------------
# Test: manifest video khoá theo ID.
# ---------------------------------------------------------------------------


def test_video_manifest_roundtrip(tmp: Path) -> None:
    project = tmp / "proj_manifest"
    project.mkdir()

    videos = vm.load_video_manifest(project)
    check("manifest rỗng khi chưa có file", videos == {})

    videos["so_sanh_nhan_thuc_binh_thuong_15_23_001"] = {
        "file_path": "assets/videos/nhan_thuc/so_sanh_nhan_thuc_binh_thuong_15_23_001.mp4",
        "ten_file_goc": "clip.mp4",
        "ngay_them": "2026-08-16T10:00:00",
    }
    vm.save_video_manifest(project, videos)

    raw = json.loads(vm.manifest_path(project).read_text(encoding="utf-8"))
    check(
        "manifest lưu đúng cấu trúc {'videos': {id: {...}}} — KHÔNG phải list nhóm",
        isinstance(raw, dict) and "videos" in raw and isinstance(raw["videos"], dict),
    )
    check(
        "manifest khoá đúng theo id",
        "so_sanh_nhan_thuc_binh_thuong_15_23_001" in raw["videos"],
    )

    reloaded = vm.load_video_manifest(project)
    check("đọc lại manifest khớp đúng dữ liệu đã lưu", reloaded == videos)


def test_video_manifest_rejects_old_list_schema(tmp: Path) -> None:
    project = tmp / "proj_old_schema"
    (project / "assets" / "reference").mkdir(parents=True)
    # Mô phỏng manifest kiểu CŨ (list nhóm theo lĩnh vực/phân loại/tuổi) —
    # phải bị từ chối rõ ràng, không được âm thầm coi là hợp lệ/rỗng.
    vm.manifest_path(project).write_text(
        json.dumps([{"id": 1, "linh_vuc": "nhan_thuc"}], ensure_ascii=False), encoding="utf-8"
    )
    raised = False
    try:
        vm.load_video_manifest(project)
    except ValueError:
        raised = True
    check("manifest kiểu cũ (list nhóm) bị từ chối rõ ràng, không đọc nhầm", raised)


# ---------------------------------------------------------------------------
# Test: gắn / thay / gỡ video theo entry.
# ---------------------------------------------------------------------------


def test_attach_video_names_file_by_id_in_domain_subfolder(tmp: Path) -> None:
    project = tmp / "proj_attach"
    project.mkdir()
    entry = make_entry("003", "giac_quan", "binh_thuong", 48, 60, "Nội dung mẫu")
    source = make_fake_video(tmp / "sources" / "my_clip.MP4")

    videos, error = vm.attach_video(project, {}, entry, source)
    check("gắn video không lỗi", error is None, detail=str(error))
    check("manifest có đúng 1 entry sau khi gắn", len(videos) == 1)

    info = videos[entry["id"]]
    expected_rel = f"assets/videos/giac_quan/{entry['id']}.mp4"
    check(
        "file_path đặt tên CHÍNH XÁC theo id (giữ đuôi file gốc, hạ thường)",
        info["file_path"] == expected_rel,
        detail=info["file_path"],
    )
    check("file thật đã được copy đúng vị trí", (project / info["file_path"]).exists())
    check("ten_file_goc lưu đúng tên file gốc trên máy người dùng", info["ten_file_goc"] == "my_clip.MP4")


def test_attach_video_replaces_old_file_when_reattached(tmp: Path) -> None:
    project = tmp / "proj_replace"
    project.mkdir()
    entry = make_entry("004", "sinh_hoc", "roi_loan_pho_tu_ky", 24, 47, "Nội dung")
    source1 = make_fake_video(tmp / "sources2" / "first.mp4", b"AAA")
    source2 = make_fake_video(tmp / "sources2" / "second.mov", b"BBB")

    videos, error1 = vm.attach_video(project, {}, entry, source1)
    check("gắn video lần 1 không lỗi", error1 is None)
    first_path = project / videos[entry["id"]]["file_path"]
    check("file video lần 1 tồn tại", first_path.exists())

    videos2, error2 = vm.attach_video(project, videos, entry, source2)
    check("gắn lại (thay thế) video lần 2 không lỗi", error2 is None, detail=str(error2))
    check("vẫn chỉ có đúng 1 entry cho id này (không nhân đôi)", len(videos2) == 1)

    second_path = project / videos2[entry["id"]]["file_path"]
    check("đường dẫn video mới đổi đúng theo đuôi file mới (.mov)", second_path.suffix == ".mov")
    check("nội dung file mới đúng (đã copy đè)", second_path.read_bytes() == b"BBB")
    check(
        "file video CŨ (đuôi .mp4) đã bị xoá khỏi đĩa, không để sót",
        not first_path.exists(),
    )


def test_attach_video_missing_source_file(tmp: Path) -> None:
    project = tmp / "proj_missing_source"
    project.mkdir()
    entry = make_entry("005", "ngon_ngu", "binh_thuong", 15, 23, "Nội dung")
    videos, error = vm.attach_video(project, {}, entry, tmp / "khong_ton_tai.mp4")
    check("gắn video với file nguồn không tồn tại -> báo lỗi rõ ràng, không crash", error is not None)
    check("manifest không đổi khi gắn thất bại", videos == {})


def test_entry_without_video_shows_normally_not_hidden(tmp: Path) -> None:
    """Yêu cầu rõ trong task: entry KHÔNG có video vẫn hiển thị bình thường
    trong danh sách lọc — không bị ẩn, không lỗi."""
    entries = [
        make_entry("006", "cam_xuc", "binh_thuong", 15, 23, "Có video"),
        make_entry("007", "cam_xuc", "binh_thuong", 15, 23, "Không có video"),
    ]
    videos = {entries[0]["id"]: {"file_path": "x", "ten_file_goc": "x", "ngay_them": "x"}}

    all_shown = vm.filter_entries(entries, videos)
    check("cả entry có và không có video đều xuất hiện khi không lọc", len(all_shown) == 2)

    only_missing = vm.filter_entries(entries, videos, only_missing_video=True)
    check(
        "lọc 'chỉ hiện chưa có video' trả về ĐÚNG entry chưa có video, không rỗng, không lỗi",
        [e["id"] for e in only_missing] == [entries[1]["id"]],
    )


def test_detach_video(tmp: Path) -> None:
    project = tmp / "proj_detach"
    project.mkdir()
    entry = make_entry("008", "quan_he_xa_hoi", "binh_thuong", 48, 60, "Nội dung")
    source = make_fake_video(tmp / "sources3" / "clip.mp4")

    videos, _ = vm.attach_video(project, {}, entry, source)
    video_path = project / videos[entry["id"]]["file_path"]
    check("file tồn tại trước khi gỡ", video_path.exists())

    remaining, error = vm.detach_video(project, videos, entry["id"])
    check("gỡ video không lỗi", error is None, detail=str(error))
    check("manifest rỗng sau khi gỡ entry duy nhất", remaining == {})
    check("file thật trên đĩa đã bị xoá", not video_path.exists())

    remaining2, error2 = vm.detach_video(project, remaining, entry["id"])
    check("gỡ lần 2 (không còn video) báo lỗi rõ ràng, không crash", error2 is not None)


# ---------------------------------------------------------------------------
# Test: lọc theo lĩnh vực/phân loại/dải tuổi/tìm kiếm.
# ---------------------------------------------------------------------------


def test_filter_entries_all_dimensions(tmp: Path) -> None:
    entries = [
        make_entry("a", "nhan_thuc", "binh_thuong", 15, 23, "Xếp chồng đồ vật"),
        make_entry("b", "nhan_thuc", "roi_loan_pho_tu_ky", 15, 23, "Không xếp chồng được"),
        make_entry("c", "ngon_ngu", "binh_thuong", 24, 47, "Nói được câu 2 từ"),
    ]
    videos: dict[str, dict] = {}

    check(
        "lọc theo linh_vuc đúng",
        {e["id"] for e in vm.filter_entries(entries, videos, linh_vuc="nhan_thuc")} == {
            "so_sanh_nhan_thuc_binh_thuong_15_23_a", "so_sanh_nhan_thuc_roi_loan_pho_tu_ky_15_23_b",
        },
    )
    check(
        "lọc theo phan_loai đúng",
        {e["id"] for e in vm.filter_entries(entries, videos, phan_loai="binh_thuong")} == {
            "so_sanh_nhan_thuc_binh_thuong_15_23_a", "so_sanh_ngon_ngu_binh_thuong_24_47_c",
        },
    )
    check(
        "lọc theo dải tuổi đúng",
        {e["id"] for e in vm.filter_entries(entries, videos, age_band_key="24_47")} == {
            "so_sanh_ngon_ngu_binh_thuong_24_47_c",
        },
    )
    check(
        "tìm theo nội dung (không phân biệt hoa/thường) đúng",
        {e["id"] for e in vm.filter_entries(entries, videos, search_text="XẾP CHỒNG")} == {
            "so_sanh_nhan_thuc_binh_thuong_15_23_a", "so_sanh_nhan_thuc_roi_loan_pho_tu_ky_15_23_b",
        },
    )
    check(
        "tìm theo id đúng",
        {e["id"] for e in vm.filter_entries(entries, videos, search_text="_c")} == {
            "so_sanh_ngon_ngu_binh_thuong_24_47_c",
        },
    )


# ---------------------------------------------------------------------------
# Test: hằng số khớp code Dart thật.
# ---------------------------------------------------------------------------


def test_domain_and_phan_loai_constants_match_dart_source() -> None:
    domains_dart = Path(__file__).parent.parent / "lib" / "core" / "constants" / "domains.dart"
    text = domains_dart.read_text(encoding="utf-8")
    for code, label in vm.DOMAINS:
        check(
            f"code+label '{code}'/'{label}' khớp domains.dart",
            f"code: '{code}'" in text and f"label: '{label}'" in text,
        )
    check("đúng 7 lĩnh vực", len(vm.DOMAINS) == 7)
    check(
        "phan_loai đúng giá trị dùng trong DB thật",
        {c for c, _ in vm.PHAN_LOAI} == {"binh_thuong", "roi_loan_pho_tu_ky"},
    )
    check(
        "dải tuổi đúng 3 cặp min/max chuẩn của dự án",
        {(b[2], b[3]) for b in vm.AGE_BANDS} == {(15, 23), (24, 47), (48, 60)},
    )


def test_constants_match_real_so_sanh_files_in_repo() -> None:
    repo_root = Path(__file__).parent.parent
    real_entries, warnings = vm.load_all_entries(repo_root)
    check("có ít nhất 1 file so_sanh_*_thang.json thật trong repo", len(real_entries) > 0)
    check("không có cảnh báo nào khi đọc dữ liệu thật trong repo", warnings == [], detail=str(warnings))
    if real_entries:
        real_linh_vuc = {e.get("linh_vuc") for e in real_entries}
        real_phan_loai = {e.get("phan_loai") for e in real_entries}
        check(
            "mọi linh_vuc trong dữ liệu thật đều nằm trong 7 lĩnh vực đã khai báo",
            real_linh_vuc <= {code for code, _ in vm.DOMAINS},
            detail=str(real_linh_vuc),
        )
        check(
            "mọi phan_loai trong dữ liệu thật đều nằm trong 2 giá trị đã khai báo",
            real_phan_loai <= {code for code, _ in vm.PHAN_LOAI},
            detail=str(real_phan_loai),
        )


# ---------------------------------------------------------------------------
# Test: cập nhật pubspec.yaml trên BẢN SAO file thật.
# ---------------------------------------------------------------------------


def run_pubspec_tests(tmp: Path) -> None:
    real_pubspec = Path(__file__).parent.parent / "pubspec.yaml"
    check("pubspec.yaml thật tồn tại trong repo", real_pubspec.exists())
    if not real_pubspec.exists():
        return

    copy_path = tmp / "pubspec_copy.yaml"
    shutil.copy2(real_pubspec, copy_path)
    original_text = copy_path.read_text(encoding="utf-8")

    declared_before = vm.declared_pubspec_asset_dirs(original_text)
    check(
        "7 thư mục lĩnh vực video đã có sẵn trong pubspec.yaml thật (mô hình mới tái dùng, không cần thêm)",
        all(f"assets/videos/{code}" in declared_before for code, _ in vm.DOMAINS),
        detail=str(sorted(declared_before)),
    )

    # Giả lập manifest video (mô hình mới) chỉ dùng đúng các thư mục ĐÃ khai báo sẵn.
    videos_all_declared = {
        "so_sanh_nhan_thuc_binh_thuong_15_23_001": {"file_path": "assets/videos/nhan_thuc/so_sanh_nhan_thuc_binh_thuong_15_23_001.mp4"},
    }
    missing_normal_case = vm.missing_pubspec_asset_dirs(
        videos_all_declared, vm.declared_pubspec_asset_dirs(original_text)
    )
    check(
        "tình huống thông thường: KHÔNG cần thêm gì vào pubspec.yaml (đã tái dùng thư mục lĩnh vực có sẵn)",
        missing_normal_case == [],
        detail=str(missing_normal_case),
    )

    # Tình huống hiếm: 1 thư mục lĩnh vực bị lỡ xoá khỏi khai báo -> vẫn phát
    # hiện + thêm lại đúng. Mô phỏng THẬT trên đĩa (xoá đúng dòng đó khỏi bản
    # sao), không chỉ tính toán trên tập hợp trong bộ nhớ — để
    # `update_pubspec_file` thao tác trên đúng trạng thái file lúc gọi.
    text_missing_one = "\n".join(
        line for line in original_text.splitlines() if line.strip() != "- assets/videos/nhan_thuc/"
    ) + "\n"
    copy_path.write_text(text_missing_one, encoding="utf-8")

    declared_missing_one = vm.declared_pubspec_asset_dirs(text_missing_one)
    missing_rare_case = vm.missing_pubspec_asset_dirs(videos_all_declared, declared_missing_one)
    check(
        "tình huống hiếm (lỡ xoá 1 dòng khai báo): phát hiện đúng thư mục còn thiếu",
        missing_rare_case == ["assets/videos/nhan_thuc"],
    )

    ok, message = vm.update_pubspec_file(copy_path, missing_rare_case)
    check("update_pubspec_file báo ghi thành công trên bản sao thật", ok, detail=message)

    backup_path = copy_path.with_suffix(copy_path.suffix + ".bak")
    check("đã tạo file backup .bak trước khi ghi", backup_path.exists())
    check(
        "nội dung backup khớp y hệt trạng thái file NGAY TRƯỚC lần ghi này",
        backup_path.read_text(encoding="utf-8") == text_missing_one,
    )

    updated_text = copy_path.read_text(encoding="utf-8")
    check("đã thêm đúng dòng thư mục còn thiếu vào pubspec.yaml (bản sao)", "- assets/videos/nhan_thuc/" in updated_text)

    # So với bản GỐC PRISTINE (trước khi test cố tình xoá dòng để mô phỏng) —
    # sau khi thêm lại, nội dung phải khớp lại y hệt bản gốc (chỉ khác thứ tự
    # dòng có thể lệch do chèn ở cuối khối — so sánh theo tập hợp dòng).
    check(
        "sau khi thêm lại, tập hợp dòng khớp lại đúng bản gốc pristine (không mất/thừa dòng nào)",
        set(original_text.splitlines()) == set(updated_text.splitlines()),
    )
    check(
        "khối 'dependencies:'/'dev_dependencies:' vẫn còn nguyên",
        "dependencies:" in updated_text and "dev_dependencies:" in updated_text and "sqflite:" in updated_text,
    )

    # Chạy lại lần 2 với cùng dữ liệu -> không thêm trùng.
    declared_after = vm.declared_pubspec_asset_dirs(updated_text)
    missing_second_run = vm.missing_pubspec_asset_dirs(videos_all_declared, declared_after)
    check("chạy lại lần 2 không phát hiện gì còn thiếu (không thêm trùng)", missing_second_run == [])

    ok2, message2 = vm.update_pubspec_file(copy_path, missing_rare_case)
    check("gọi update_pubspec_file lần 2 với cùng dữ liệu -> không ghi gì thêm", ok2 is False, detail=message2)

    final_text = copy_path.read_text(encoding="utf-8")
    check(
        "dòng vừa thêm chỉ xuất hiện đúng 1 lần sau khi chạy 2 lần (không trùng lặp)",
        final_text.count("- assets/videos/nhan_thuc/") == 1,
    )


# ---------------------------------------------------------------------------
# Test GIAO DIỆN THẬT — dựng `tk.Tk()` thật (không `mainloop()`), dựng widget
# thật, đo hành vi hiển thị/lọc/hiệu năng. Đây là test cho yêu cầu "load full
# toàn bộ id kèm nội dung ngay trên màn hình" — không thể xác nhận bằng test
# logic thuần, phải dựng UI thật để đếm khối đã pack/hiển thị.
# ---------------------------------------------------------------------------


def _collect_widget_texts(widget) -> list[str]:
    """Duyệt đệ quy toàn bộ widget con, thu thập text của mọi widget có
    thuộc tính "text" (Label, Button, ...) — dùng để xác nhận nội dung THẬT
    có mặt trong cây widget, không chỉ tin thuộc tính nội bộ của app."""
    texts: list[str] = []
    if hasattr(widget, "cget"):
        try:
            if "text" in widget.keys():
                texts.append(widget.cget("text"))
        except Exception:
            pass
    for child in widget.winfo_children():
        texts.extend(_collect_widget_texts(child))
    return texts


def _make_hidden_root():
    """Tạo `tk.Tk()` THẬT nhưng ẩn ngay (không hiện cửa sổ trên màn hình) —
    dùng cho test. Trả về None nếu môi trường không có display (tkinter
    không tạo được cửa sổ) thay vì làm cả bộ test crash."""
    tk, ttk, filedialog, messagebox, VideoManagerApp = vm.build_app_class()
    try:
        root = tk.Tk()
    except Exception as exc:  # tkinter.TclError khi không có display
        print(f"[SKIP] Không tạo được cửa sổ Tk thật trong môi trường này ({exc}) — bỏ qua nhóm test giao diện.")
        return None, None
    root.withdraw()
    return root, VideoManagerApp


def test_gui_loads_full_list_immediately_on_open_project(tmp: Path) -> None:
    root, VideoManagerApp = _make_hidden_root()
    if root is None:
        return
    try:
        project = tmp / "proj_gui_full"
        make_fake_so_sanh_file(
            project, "so_sanh_15_23_thang.json", 15, 23,
            [make_entry(f"{i:03d}", "nhan_thuc", "binh_thuong", 15, 23, f"Nội dung số {i}") for i in range(5)],
        )
        make_fake_so_sanh_file(
            project, "so_sanh_24_47_thang.json", 24, 47,
            [make_entry(f"{i:03d}", "ngon_ngu", "roi_loan_pho_tu_ky", 24, 47, f"Nội dung ngôn ngữ {i}") for i in range(3)],
        )

        app = VideoManagerApp(root)
        app.open_project(project)  # KHÔNG qua hộp thoại, KHÔNG cần gõ tìm/bấm gì thêm

        check(
            "mở dự án xong -> dựng ĐỦ khối cho TẤT CẢ entry (5 + 3 = 8), không cần thao tác thêm",
            len(app.block_frames) == 8,
            detail=str(len(app.block_frames)),
        )
        visible = [eid for eid, f in app.block_frames.items() if f.winfo_manager() == "pack"]
        check(
            "mặc định (chưa lọc, chưa tìm) TOÀN BỘ 8 khối đều đang hiển thị (pack), không ẩn cái nào",
            len(visible) == 8,
            detail=str(len(visible)),
        )

        # Nội dung ĐẦY ĐỦ phải có sẵn ngay trong widget — không phải rút gọn,
        # không cần bấm chọn dòng nào để "mở ra" mới thấy.
        sample_entry = app.entries[0]
        block = app.block_frames[sample_entry["id"]]
        all_texts = _collect_widget_texts(block)
        check(
            "nội dung ĐẦY ĐỦ (không rút gọn) đã có sẵn trong khối ngay khi dựng, không cần click",
            sample_entry["content"] in all_texts,
            detail=str(all_texts),
        )
        check(
            "id đầy đủ cũng hiển thị sẵn ngay trong khối",
            sample_entry["id"] in all_texts,
        )
    finally:
        root.destroy()


def test_gui_filter_by_domain_hides_others_keeps_full_content(tmp: Path) -> None:
    root, VideoManagerApp = _make_hidden_root()
    if root is None:
        return
    try:
        project = tmp / "proj_gui_filter"
        make_fake_so_sanh_file(
            project, "so_sanh_15_23_thang.json", 15, 23,
            [
                make_entry("001", "nhan_thuc", "binh_thuong", 15, 23, "A"),
                make_entry("002", "nhan_thuc", "roi_loan_pho_tu_ky", 15, 23, "B"),
                make_entry("003", "ngon_ngu", "binh_thuong", 15, 23, "C"),
            ],
        )
        app = VideoManagerApp(root)
        app.open_project(project)

        app.filter_domain_var.set("Nhận thức")
        app._apply_filters()

        visible_ids = {eid for eid, f in app.block_frames.items() if f.winfo_manager() == "pack"}
        check(
            "lọc theo lĩnh vực 'Nhận thức' -> chỉ còn đúng 2 khối thuộc lĩnh vực đó",
            visible_ids == {"so_sanh_nhan_thuc_binh_thuong_15_23_001", "so_sanh_nhan_thuc_roi_loan_pho_tu_ky_15_23_002"},
            detail=str(visible_ids),
        )
        check(
            "3 khối vẫn tồn tại trong bộ nhớ (chỉ ẩn, không huỷ) — không dựng lại khi lọc",
            len(app.block_frames) == 3,
        )

        app.filter_domain_var.set("Tất cả")
        app._apply_filters()
        visible_after_reset = {eid for eid, f in app.block_frames.items() if f.winfo_manager() == "pack"}
        check("bỏ lọc -> hiện lại đủ cả 3 khối", len(visible_after_reset) == 3)
    finally:
        root.destroy()


def test_gui_only_missing_video_checkbox(tmp: Path) -> None:
    root, VideoManagerApp = _make_hidden_root()
    if root is None:
        return
    try:
        project = tmp / "proj_gui_missing"
        make_fake_so_sanh_file(
            project, "so_sanh_15_23_thang.json", 15, 23,
            [
                make_entry("001", "cam_xuc", "binh_thuong", 15, 23, "Có video"),
                make_entry("002", "cam_xuc", "binh_thuong", 15, 23, "Chưa có video"),
            ],
        )
        source = make_fake_video(tmp / "gui_sources" / "clip.mp4")

        app = VideoManagerApp(root)
        app.open_project(project)

        target_id = "so_sanh_cam_xuc_binh_thuong_15_23_001"
        error = app.apply_attach(target_id, source)
        check("gắn video qua apply_attach() (không qua hộp thoại) không lỗi", error is None, detail=str(error))

        app.only_missing_var.set(True)
        app._apply_filters()
        visible_ids = {eid for eid, f in app.block_frames.items() if f.winfo_manager() == "pack"}
        check(
            "bật 'chỉ hiện chưa có video' -> id đã gắn video biến mất, chỉ còn id chưa có",
            visible_ids == {"so_sanh_cam_xuc_binh_thuong_15_23_002"},
            detail=str(visible_ids),
        )

        # Khối của entry ĐÃ gắn video phải hiện đúng trạng thái (nút "Thay video"/"Gỡ video")
        # ngay tại chỗ, không cần dựng lại toàn bộ danh sách.
        status_frame = app.status_frames[target_id]
        button_texts = [w.cget("text") for w in status_frame.winfo_children() if hasattr(w, "cget") and "text" in w.keys()]
        check(
            "khối đã gắn video hiện đúng nút 'Thay video...'/'Gỡ video' tại chỗ, không cần dựng lại",
            "Thay video..." in button_texts and "Gỡ video" in button_texts,
            detail=str(button_texts),
        )
    finally:
        root.destroy()


def test_gui_performance_with_real_repo_data() -> None:
    """Đo thời gian dựng UI với dữ liệu THẬT của repo (200+ entry sau khi
    gộp 2 file so_sanh_*_thang.json hiện có)."""
    import time

    root, VideoManagerApp = _make_hidden_root()
    if root is None:
        return
    try:
        repo_root = Path(__file__).parent.parent
        app = VideoManagerApp(root)

        start = time.perf_counter()
        app.open_project(repo_root)
        elapsed = time.perf_counter() - start

        entry_count = len(app.entries)
        check(f"dựng UI với dữ liệu thật ({entry_count} entry) không lỗi", entry_count > 0)
        check(
            f"dựng {entry_count} khối trong {elapsed:.2f}s — dựng 1 lần khi mở dự án, đủ nhanh (<5s) để không cảm giác treo",
            elapsed < 5.0,
            detail=f"{elapsed:.2f}s",
        )
        print(f"    (đo hiệu năng: {entry_count} entry -> {elapsed:.2f}s dựng UI ban đầu)")

        # Sau khi đã dựng xong, gõ tìm kiếm/lọc chỉ ẩn-hiện — phải NHANH hơn
        # hẳn lần dựng đầu (không dựng lại widget).
        start2 = time.perf_counter()
        app.search_var.set("không thể tồn tại trong nội dung thật xyz123")
        app._apply_filters()
        elapsed_filter = time.perf_counter() - start2
        check(
            f"lọc/tìm kiếm sau khi đã dựng xong CHỈ ẩn/hiện, nhanh hơn hẳn lần dựng đầu ({elapsed_filter:.3f}s so với {elapsed:.2f}s)",
            elapsed_filter < elapsed,
            detail=f"filter={elapsed_filter:.3f}s build={elapsed:.2f}s",
        )
    finally:
        root.destroy()


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="video_manager_test_") as tmp_str:
        tmp = Path(tmp_str)

        original_config_file = vm.CONFIG_FILE
        vm.CONFIG_FILE = tmp / ".video_manager_config_test.json"

        test_find_and_load_all_entries(tmp)
        test_load_all_entries_handles_duplicate_and_malformed(tmp)
        test_load_all_entries_missing_dir(tmp)
        test_video_manifest_roundtrip(tmp)
        test_video_manifest_rejects_old_list_schema(tmp)
        test_attach_video_names_file_by_id_in_domain_subfolder(tmp)
        test_attach_video_replaces_old_file_when_reattached(tmp)
        test_attach_video_missing_source_file(tmp)
        test_entry_without_video_shows_normally_not_hidden(tmp)
        test_detach_video(tmp)
        test_filter_entries_all_dimensions(tmp)
        test_domain_and_phan_loai_constants_match_dart_source()
        test_constants_match_real_so_sanh_files_in_repo()
        run_pubspec_tests(tmp)

        test_gui_loads_full_list_immediately_on_open_project(tmp)
        test_gui_filter_by_domain_hides_others_keeps_full_content(tmp)
        test_gui_only_missing_video_checkbox(tmp)
        test_gui_performance_with_real_repo_data()

        vm.CONFIG_FILE = original_config_file

    total = len(_results)
    failed = [name for name, ok, _ in _results if not ok]
    print(f"\n=== {total - len(failed)}/{total} PASS ===")
    if failed:
        print("FAILED:")
        for name in failed:
            print(f"  - {name}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
