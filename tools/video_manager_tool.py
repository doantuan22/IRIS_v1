#!/usr/bin/env python3
"""Tool GUI gắn video mẫu tham khảo vào ĐÚNG TỪNG ID entry "So sánh".

DEV TOOL độc lập — KHÔNG phải một phần của app Flutter, không được build cùng
app, không viết bằng Dart. Chạy bằng:

    python tools/video_manager_tool.py

Chỉ dùng thư viện chuẩn Python (tkinter, json, shutil, pathlib, re, datetime)
— không cần `pip install` gì cả.

=== MÔ HÌNH DỮ LIỆU (audit trước khi viết code, xem SETUP_REPORT.md) ===
Dữ liệu "So sánh" nằm trong các file `assets/reference/so_sanh_*_thang.json`
(hiện có `so_sanh_15_23_thang.json`, `so_sanh_24_47_thang.json`; sẽ có thêm
`so_sanh_48_60_thang.json` sau — tool tự dò glob, không hard-code tên file).
Mỗi file có field `entries` (list), mỗi entry có `id` DUY NHẤT toàn cục (VD
"so_sanh_nhan_thuc_binh_thuong_15_23_001"), cùng `linh_vuc`, `phan_loai`,
`do_tuoi_thang_min/max`, `content`, `nguon_tai_lieu`.

VIDEO GẮN THEO TỪNG ID — KHÔNG theo nhóm lĩnh vực/phân loại/dải tuổi. Không
bắt buộc mọi id đều có video (phần lớn không có, chỉ 1 số id được chọn để gắn
video minh hoạ) — đây là bản THIẾT KẾ LẠI thay thế hoàn toàn mô hình "video
theo tổ hợp lĩnh vực×phân loại×dải tuổi" của bản trước (mô hình cũ SAI so với
cách dữ liệu thật được tổ chức — mỗi id là 1 nội dung riêng biệt, không phải
đại diện cho cả nhóm).

Thư mục lưu video: `assets/videos/{linh_vuc}/{id}.{đuôi file gốc}` — tên file
= chính xác id của entry (không thể nhầm lẫn), đặt trong thư mục con theo
`linh_vuc` để tái dùng ĐÚNG 7 thư mục `assets/videos/{linh_vuc}/` đã được khai
báo sẵn trong `pubspec.yaml` từ trước (khớp `Domain.code` trong
`lib/core/constants/domains.dart`) — nhờ vậy trong tình huống thông thường
KHÔNG cần sửa `pubspec.yaml` thêm lần nào nữa. Tính năng "Cập nhật
pubspec.yaml" vẫn được giữ lại để phòng trường hợp hiếm (thư mục lĩnh vực nào
đó lỡ bị xoá khỏi khai báo).

Manifest JSON: `assets/reference/video_manifest.json` — khoá THEO ID:
    {"videos": {"<id>": {"file_path": ..., "ten_file_goc": ..., "ngay_them": ...}}}
KHÔNG dùng cấu trúc list nhóm theo lĩnh vực/phân loại/tuổi của bản trước — chỉ
1 mô hình duy nhất (theo id) để tránh 2 nguồn sự thật.
"""

from __future__ import annotations

import json
import re
import shutil
from datetime import datetime
from pathlib import Path

# ---------------------------------------------------------------------------
# Hằng số — copy chính xác từ code Dart thật của dự án, KHÔNG gõ lại từ trí nhớ.
# ---------------------------------------------------------------------------

# (code, nhãn tiếng Việt) — khớp chính xác `domains` trong
# lib/core/constants/domains.dart. Dùng để hiện nhãn/lọc, KHÔNG dùng để chọn
# nơi gắn video (nơi gắn video lấy trực tiếp từ `linh_vuc` của entry đang chọn).
DOMAINS: list[tuple[str, str]] = [
    ("nhan_thuc", "Nhận thức"),
    ("cam_xuc", "Cảm xúc"),
    ("giac_quan", "Giác quan"),
    ("quan_he_xa_hoi", "Quan hệ xã hội"),
    ("ngon_ngu", "Ngôn ngữ"),
    ("sinh_hoc", "Sinh học"),
    ("sinh_hoat_ca_nhan", "Sinh hoạt cá nhân"),
]

# (code, nhãn tiếng Việt) — khớp giá trị `phan_loai` dùng cho content_type='so_sanh'.
PHAN_LOAI: list[tuple[str, str]] = [
    ("binh_thuong", "Trẻ bình thường"),
    ("roi_loan_pho_tu_ky", "Trẻ tự kỷ"),
]

# (key, nhãn, min, max) — 3 dải tuổi cố định, dùng cho dropdown lọc theo dải tuổi.
AGE_BANDS: list[tuple[str, str, int, int]] = [
    ("15_23", "15 - 23 tháng", 15, 23),
    ("24_47", "24 - 47 tháng", 24, 47),
    ("48_60", "48 - 60 tháng", 48, 60),
]

DOMAIN_LABELS = dict(DOMAINS)
PHAN_LOAI_LABELS = dict(PHAN_LOAI)

SO_SANH_GLOB = "so_sanh_*_thang.json"
SO_SANH_REL_DIR = Path("assets/reference")
MANIFEST_REL_PATH = Path("assets/reference/video_manifest.json")
VIDEO_EXTENSIONS = {".mp4", ".mov", ".m4v", ".webm", ".avi", ".mkv"}

CONFIG_FILE = Path(__file__).with_name(".video_manager_config.json")

PUBSPEC_ASSET_LINE_RE = re.compile(r"^(?P<indent>[ \t]*)-\s+(?P<path>assets/\S+?)/?\s*$")
PUBSPEC_ASSETS_KEY_RE = re.compile(r"^(?P<indent>[ \t]*)assets:\s*$")


# ---------------------------------------------------------------------------
# Nạp entry từ các file so_sanh_*_thang.json — logic thuần, không phụ thuộc
# tkinter, test được bằng cách import thẳng module này.
# ---------------------------------------------------------------------------


def find_so_sanh_files(project_root: Path) -> list[Path]:
    """Tự dò tất cả file khớp `so_sanh_*_thang.json` trong `assets/reference/`
    — KHÔNG hard-code tên file cụ thể, để tự nhận file mới (VD
    `so_sanh_48_60_thang.json`) khi được thêm vào sau này mà không cần sửa
    code."""
    search_dir = project_root / SO_SANH_REL_DIR
    if not search_dir.exists():
        return []
    return sorted(search_dir.glob(SO_SANH_GLOB))


def load_all_entries(project_root: Path) -> tuple[list[dict], list[str]]:
    """Đọc TẤT CẢ file so_sanh_*_thang.json, gộp `entries` lại thành 1 danh
    sách chung — mỗi entry được gắn thêm `_source_file` (tên file gốc, để
    biết entry thuộc file nào). Entry trùng `id` (không nên xảy ra, nhưng đề
    phòng) chỉ giữ bản xuất hiện trước, các bản sau bị bỏ qua kèm cảnh báo.
    Trả về (entries, warnings) — 1 file lỗi không làm hỏng việc đọc các file
    còn lại."""
    entries: list[dict] = []
    seen_ids: set[str] = set()
    warnings: list[str] = []

    for path in find_so_sanh_files(project_root):
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError) as exc:
            warnings.append(f"Không đọc được {path.name}: {exc}")
            continue

        file_entries = data.get("entries")
        if not isinstance(file_entries, list):
            warnings.append(f"{path.name}: thiếu field 'entries' dạng list — bỏ qua file này.")
            continue

        for entry in file_entries:
            entry_id = entry.get("id")
            if not entry_id:
                warnings.append(f"{path.name}: có entry thiếu 'id' — bỏ qua entry đó.")
                continue
            if entry_id in seen_ids:
                warnings.append(f"{path.name}: id trùng lặp '{entry_id}' — chỉ giữ bản xuất hiện trước.")
                continue
            seen_ids.add(entry_id)
            entries.append({**entry, "_source_file": path.name})

    return entries, warnings


def entries_by_id(entries: list[dict]) -> dict[str, dict]:
    return {e["id"]: e for e in entries}


# ---------------------------------------------------------------------------
# Manifest video — khoá THEO ID (1 mô hình duy nhất).
# ---------------------------------------------------------------------------


def manifest_path(project_root: Path) -> Path:
    return project_root / MANIFEST_REL_PATH


def load_video_manifest(project_root: Path) -> dict[str, dict]:
    """Đọc manifest, trả về dict {id: {file_path, ten_file_goc, ngay_them}}.
    {} nếu file chưa tồn tại. Ném lỗi rõ ràng nếu file hỏng (JSON lỗi hoặc
    thiếu field "videos") thay vì âm thầm mất dữ liệu người dùng đã gắn."""
    path = manifest_path(project_root)
    if not path.exists():
        return {}
    text = path.read_text(encoding="utf-8")
    if not text.strip():
        return {}
    data = json.loads(text)
    if not isinstance(data, dict) or "videos" not in data or not isinstance(data["videos"], dict):
        raise ValueError(f"Manifest {path} không đúng định dạng (phải có field 'videos' dạng object).")
    return data["videos"]


def save_video_manifest(project_root: Path, videos: dict[str, dict]) -> None:
    path = manifest_path(project_root)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps({"videos": videos}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )


def video_dest_path(project_root: Path, linh_vuc: str, entry_id: str, ext: str) -> Path:
    return project_root / "assets" / "videos" / linh_vuc / f"{entry_id}{ext}"


def video_asset_rel_path(linh_vuc: str, entry_id: str, ext: str) -> str:
    """Đường dẫn asset kiểu Flutter (luôn dùng "/", kể cả chạy trên Windows)
    — dùng để ghi vào manifest["videos"][id]["file_path"]."""
    return f"assets/videos/{linh_vuc}/{entry_id}{ext}"


def attach_video(
    project_root: Path,
    videos: dict[str, dict],
    entry: dict,
    source_path: Path,
) -> tuple[dict[str, dict], str | None]:
    """Gắn 1 video vào [entry] (copy file, đặt tên = id + đuôi file gốc). Nếu
    entry đã có video từ trước, XOÁ file cũ trước khi copy file mới (việc hỏi
    xác nhận thay thế thuộc về tầng GUI, không phải hàm thuần này). Trả về
    (videos mới — KHÔNG sửa dict truyền vào, thông báo lỗi nếu có)."""
    entry_id = entry.get("id")
    linh_vuc = entry.get("linh_vuc")
    if not entry_id:
        return videos, "Entry không có 'id'."
    if not linh_vuc:
        return videos, f"Entry '{entry_id}' không có 'linh_vuc'."
    if not source_path.exists():
        return videos, f"Không tìm thấy file nguồn: {source_path}"

    new_videos = dict(videos)

    old = new_videos.get(entry_id)
    if old:
        old_path = project_root / old.get("file_path", "")
        if old_path.exists():
            try:
                old_path.unlink()
            except OSError as exc:
                return videos, f"Không xoá được video cũ trước khi thay thế: {exc}"

    ext = source_path.suffix.lower() or ".mp4"
    dest_path = video_dest_path(project_root, linh_vuc, entry_id, ext)
    dest_path.parent.mkdir(parents=True, exist_ok=True)

    try:
        shutil.copy2(source_path, dest_path)
    except OSError as exc:
        return videos, f"Lỗi khi copy video: {exc}"

    new_videos[entry_id] = {
        "file_path": video_asset_rel_path(linh_vuc, entry_id, ext),
        "ten_file_goc": source_path.name,
        "ngay_them": datetime.now().isoformat(timespec="seconds"),
    }
    return new_videos, None


def detach_video(project_root: Path, videos: dict[str, dict], entry_id: str) -> tuple[dict[str, dict], str | None]:
    """Gỡ video khỏi 1 entry: xoá file thật (nếu còn) + xoá khoá khỏi
    manifest. Trả về (videos mới, lỗi nếu có — None nếu thành công)."""
    target = videos.get(entry_id)
    if target is None:
        return videos, f"Entry '{entry_id}' hiện không có video nào để gỡ."

    file_path = project_root / target.get("file_path", "")
    if file_path.exists():
        try:
            file_path.unlink()
        except OSError as exc:
            return videos, f"Không xoá được file trên đĩa: {exc}"

    new_videos = dict(videos)
    del new_videos[entry_id]
    return new_videos, None


# ---------------------------------------------------------------------------
# Lọc/tìm kiếm entry — dùng chung cho bảng danh sách trong GUI.
# ---------------------------------------------------------------------------


def filter_entries(
    entries: list[dict],
    videos: dict[str, dict],
    *,
    linh_vuc: str | None = None,
    phan_loai: str | None = None,
    age_band_key: str | None = None,
    only_missing_video: bool = False,
    search_text: str = "",
) -> list[dict]:
    result = entries

    if linh_vuc:
        result = [e for e in result if e.get("linh_vuc") == linh_vuc]
    if phan_loai:
        result = [e for e in result if e.get("phan_loai") == phan_loai]
    if age_band_key:
        band = next((b for b in AGE_BANDS if b[0] == age_band_key), None)
        if band is not None:
            _, _, band_min, band_max = band
            result = [
                e for e in result
                if e.get("do_tuoi_thang_min") == band_min and e.get("do_tuoi_thang_max") == band_max
            ]
    if only_missing_video:
        result = [e for e in result if e.get("id") not in videos]

    text = search_text.strip().lower()
    if text:
        result = [
            e for e in result
            if text in str(e.get("id", "")).lower() or text in str(e.get("content", "")).lower()
        ]

    return result


# ---------------------------------------------------------------------------
# Config nhớ project_root lần trước.
# ---------------------------------------------------------------------------


def load_config() -> dict:
    if not CONFIG_FILE.exists():
        return {}
    try:
        return json.loads(CONFIG_FILE.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return {}


def save_config(data: dict) -> None:
    CONFIG_FILE.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")


# ---------------------------------------------------------------------------
# Cập nhật pubspec.yaml — chỉ thêm dòng còn thiếu trong khối `flutter: > assets:`,
# không đụng tới bất kỳ khối nào khác. Có backup trước khi ghi. (Giữ nguyên
# logic từ bản trước — thuần tuý xử lý text, không phụ thuộc mô hình dữ liệu
# video theo nhóm hay theo id.)
# ---------------------------------------------------------------------------


def declared_pubspec_asset_dirs(pubspec_text: str) -> set[str]:
    declared = set()
    for line in pubspec_text.splitlines():
        m = PUBSPEC_ASSET_LINE_RE.match(line)
        if m:
            declared.add(m.group("path"))
    return declared


def missing_pubspec_asset_dirs(videos: dict[str, dict], declared: set[str]) -> list[str]:
    """Từ manifest video (khoá theo id), suy ra các thư mục `assets/videos/{linh_vuc}/`
    cần khai báo trong pubspec.yaml mà CHƯA có. Trong tình huống thông thường
    danh sách này RỖNG vì cả 7 thư mục lĩnh vực đã được khai báo sẵn từ
    trước — chỉ khác rỗng nếu 1 dòng khai báo nào đó lỡ bị xoá."""
    needed = set()
    for info in videos.values():
        file_path = info.get("file_path", "")
        if not file_path:
            continue
        rel_dir = str(Path(file_path).parent.as_posix())
        needed.add(rel_dir)
    return sorted(needed - declared)


def update_pubspec_file(pubspec_path: Path, new_dirs: list[str]) -> tuple[bool, str]:
    """Thêm [new_dirs] (đã lọc trước — chỉ những dòng thật sự còn thiếu) vào
    khối `assets:` của [pubspec_path]. Backup file gốc thành `.bak` trước khi
    ghi. KHÔNG đụng tới bất kỳ dòng nào khác trong file."""
    if not new_dirs:
        return False, "Không có thư mục nào cần thêm — pubspec.yaml đã đầy đủ."

    if not pubspec_path.exists():
        return False, f"Không tìm thấy {pubspec_path}."

    original_text = pubspec_path.read_text(encoding="utf-8")
    declared = declared_pubspec_asset_dirs(original_text)
    to_add = [d for d in new_dirs if d not in declared]
    if not to_add:
        return False, "Không có thư mục nào cần thêm — pubspec.yaml đã đầy đủ."

    lines = original_text.splitlines(keepends=True)

    last_asset_line_idx = None
    indent = "    "
    for idx, line in enumerate(lines):
        m = PUBSPEC_ASSET_LINE_RE.match(line.rstrip("\r\n"))
        if m:
            last_asset_line_idx = idx
            indent = m.group("indent")

    if last_asset_line_idx is None:
        assets_key_idx = None
        for idx, line in enumerate(lines):
            m = PUBSPEC_ASSETS_KEY_RE.match(line.rstrip("\r\n"))
            if m:
                assets_key_idx = idx
                indent = m.group("indent") + "  "
        if assets_key_idx is None:
            return False, "Không tìm thấy khối 'assets:' trong pubspec.yaml — không tự ý thêm để tránh ghi sai vị trí."
        insert_at = assets_key_idx + 1
    else:
        insert_at = last_asset_line_idx + 1

    new_lines = [f"{indent}- {d}/\n" for d in to_add]

    backup_path = pubspec_path.with_suffix(pubspec_path.suffix + ".bak")
    shutil.copy2(pubspec_path, backup_path)

    updated_lines = lines[:insert_at] + new_lines + lines[insert_at:]
    pubspec_path.write_text("".join(updated_lines), encoding="utf-8")

    return True, f"Đã thêm {len(to_add)} thư mục vào pubspec.yaml (backup: {backup_path.name})."


def _code_for_label(pairs: list[tuple[str, str]], label: str) -> str | None:
    """Trả về None cho "Tất cả" hoặc nhãn không khớp (coi như không lọc theo
    trường đó). Không phụ thuộc tkinter — dùng chung cho cả GUI lẫn test."""
    if label == "Tất cả":
        return None
    for code, lbl in pairs:
        if lbl == label:
            return code
    return None


# ---------------------------------------------------------------------------
# Giao diện Tkinter — GIAO DIỆN CUỘN, HIỂN THỊ ĐẦY ĐỦ NGAY (không phải bảng
# rút gọn kiểu Treeview + panel chọn-mới-xem của bản trước). Mở dự án xong là
# thấy TOÀN BỘ id kèm full nội dung, cuộn xem lần lượt, gắn video ngay tại
# chỗ — không cần bấm chọn, không cần gõ tìm mới thấy.
#
# `build_app_class()` tách khỏi `_run_gui()` để TEST được bằng `tk.Tk()` THẬT
# (dựng widget thật, đo được số khối/hành vi lọc/hiệu năng) mà không cần chạy
# `mainloop()` — `import video_manager_tool` (không gọi hàm này) vẫn KHÔNG
# đụng tới tkinter, giữ đúng yêu cầu import module không cần môi trường GUI.
# ---------------------------------------------------------------------------


def build_app_class():
    """Import tkinter + định nghĩa `VideoManagerApp`, trả về
    (tk, ttk, filedialog, messagebox, VideoManagerApp). Gọi hàm này (thay vì
    import tkinter ở đầu file) để module vẫn import được ở môi trường không
    có tkinter/không có display — chỉ cần tkinter thật khi thực sự dựng UI
    (chạy `_run_gui()` hoặc test dựng widget thật)."""
    import tkinter as tk
    from tkinter import filedialog, messagebox, ttk

    class VideoManagerApp:
        """Toàn bộ trạng thái/UI của tool. Các hành động có hộp thoại
        (`_prompt_project_root`, `_attach_video`, `_detach_video`,
        `_update_pubspec`) tách riêng khỏi phần logic thuần bên dưới
        (`open_project`, `apply_attach`, `apply_detach`) để test gọi thẳng
        phần logic mà không bật hộp thoại thật nào."""

        def __init__(self, root: tk.Tk) -> None:
            self.root = root
            self.root.title("IRIS — Gắn video mẫu tham khảo theo entry")
            self.root.geometry("1200x760")

            self.project_root: Path | None = None
            self.entries: list[dict] = []
            self.entries_by_id: dict[str, dict] = {}
            self.videos: dict[str, dict] = {}
            self.block_frames: dict[str, tk.Frame] = {}
            self.status_frames: dict[str, tk.Frame] = {}

            self._build_ui()

            config = load_config()
            stored = config.get("project_root")
            if stored and Path(stored).exists():
                self.open_project(Path(stored))

        # -- Thiết lập UI ------------------------------------------------

        def _build_ui(self) -> None:
            top = tk.Frame(self.root, padx=10, pady=8)
            top.pack(fill="x")
            self.project_label = tk.Label(top, text="Chưa chọn thư mục dự án", anchor="w")
            self.project_label.pack(side="left", fill="x", expand=True)
            tk.Button(top, text="Chọn thư mục dự án...", command=self._prompt_project_root).pack(side="right")
            tk.Button(top, text="Cập nhật pubspec.yaml...", command=self._update_pubspec).pack(side="right", padx=(0, 8))

            # Thanh lọc CỐ ĐỊNH phía trên, không cuộn theo danh sách.
            filter_frame = tk.LabelFrame(self.root, text="Lọc (tuỳ chọn — không lọc gì thì thấy TOÀN BỘ)", padx=10, pady=8)
            filter_frame.pack(fill="x", padx=10, pady=6)

            tk.Label(filter_frame, text="Tìm theo id/nội dung (hỗ trợ thêm, không bắt buộc):").grid(row=0, column=0, columnspan=2, sticky="w")
            self.search_var = tk.StringVar()
            search_entry = tk.Entry(filter_frame, textvariable=self.search_var, width=32)
            search_entry.grid(row=1, column=0, columnspan=2, sticky="w", pady=(2, 6))
            search_entry.bind("<KeyRelease>", lambda _e: self._apply_filters())

            tk.Label(filter_frame, text="Lĩnh vực:").grid(row=0, column=2, sticky="w", padx=(16, 0))
            self.filter_domain_var = tk.StringVar(value="Tất cả")
            ttk.Combobox(
                filter_frame, textvariable=self.filter_domain_var,
                values=["Tất cả"] + [label for _, label in DOMAINS],
                state="readonly", width=20,
            ).grid(row=1, column=2, sticky="w", padx=(16, 0))

            tk.Label(filter_frame, text="Phân loại:").grid(row=0, column=3, sticky="w", padx=(16, 0))
            self.filter_phan_loai_var = tk.StringVar(value="Tất cả")
            ttk.Combobox(
                filter_frame, textvariable=self.filter_phan_loai_var,
                values=["Tất cả"] + [label for _, label in PHAN_LOAI],
                state="readonly", width=16,
            ).grid(row=1, column=3, sticky="w", padx=(16, 0))

            tk.Label(filter_frame, text="Dải tuổi:").grid(row=0, column=4, sticky="w", padx=(16, 0))
            self.filter_age_var = tk.StringVar(value="Tất cả")
            ttk.Combobox(
                filter_frame, textvariable=self.filter_age_var,
                values=["Tất cả"] + [label for _, label, _, _ in AGE_BANDS],
                state="readonly", width=14,
            ).grid(row=1, column=4, sticky="w", padx=(16, 0))

            self.only_missing_var = tk.BooleanVar(value=False)
            tk.Checkbutton(
                filter_frame, text="Chỉ hiện các id CHƯA có video", variable=self.only_missing_var,
                command=self._apply_filters,
            ).grid(row=1, column=5, sticky="w", padx=(20, 0))

            for var in (self.filter_domain_var, self.filter_phan_loai_var, self.filter_age_var):
                var.trace_add("write", lambda *_a: self._apply_filters())

            self.status_label = tk.Label(self.root, text="", anchor="w", fg="#555")
            self.status_label.pack(fill="x", padx=10)

            # Khung cuộn dọc: Canvas + Frame + Scrollbar (Tkinter không có
            # sẵn 1 scrollable frame dựng sẵn).
            scroll_container = tk.Frame(self.root)
            scroll_container.pack(fill="both", expand=True, padx=10, pady=(4, 10))

            self.canvas = tk.Canvas(scroll_container, highlightthickness=0)
            scrollbar = ttk.Scrollbar(scroll_container, orient="vertical", command=self.canvas.yview)
            self.list_frame = tk.Frame(self.canvas)

            self.list_frame.bind(
                "<Configure>",
                lambda _e: self.canvas.configure(scrollregion=self.canvas.bbox("all")),
            )
            self._canvas_window = self.canvas.create_window((0, 0), window=self.list_frame, anchor="nw")
            self.canvas.bind(
                "<Configure>",
                lambda e: self.canvas.itemconfigure(self._canvas_window, width=e.width),
            )
            self.canvas.configure(yscrollcommand=scrollbar.set)

            self.canvas.pack(side="left", fill="both", expand=True)
            scrollbar.pack(side="right", fill="y")

            # Cuộn bằng chuột giữa — chỉ bật khi con trỏ đang ở trên danh sách.
            def _on_mousewheel(event: object) -> None:
                delta = getattr(event, "delta", 0)
                self.canvas.yview_scroll(int(-1 * (delta / 120)), "units")

            self.canvas.bind("<Enter>", lambda _e: self.canvas.bind_all("<MouseWheel>", _on_mousewheel))
            self.canvas.bind("<Leave>", lambda _e: self.canvas.unbind_all("<MouseWheel>"))

        # -- Nạp dữ liệu + dựng khối (build 1 lần, sau đó chỉ ẩn/hiện) -----

        def open_project(self, path: Path) -> None:
            """Mở dự án theo đường dẫn có sẵn (không qua hộp thoại) — dùng
            cho cả luồng thật (sau khi người dùng chọn thư mục) lẫn test (gọi
            thẳng, không cần giả lập hộp thoại chọn thư mục)."""
            self.project_root = Path(path)
            save_config({"project_root": str(self.project_root)})

            self.entries, warnings = load_all_entries(self.project_root)
            self.entries_by_id = entries_by_id(self.entries)
            try:
                self.videos = load_video_manifest(self.project_root)
            except (json.JSONDecodeError, ValueError) as exc:
                messagebox.showerror("Lỗi đọc manifest video", str(exc))
                self.videos = {}

            source_files = find_so_sanh_files(self.project_root)
            self.project_label.config(
                text=f"Dự án: {self.project_root}  —  {len(self.entries)} entry từ {len(source_files)} file so_sanh_*_thang.json"
            )

            self._build_all_blocks()
            self._apply_filters()

            if warnings:
                messagebox.showwarning("Cảnh báo khi đọc dữ liệu", "\n".join(warnings))

        def _build_all_blocks(self) -> None:
            """Dựng TOÀN BỘ khối 1 lần khi nạp dữ liệu — lọc/tìm kiếm sau đó
            CHỈ ẩn/hiện (pack/pack_forget) các khối đã dựng sẵn, không dựng
            lại, để gõ phím tìm kiếm không bị giật với danh sách dài."""
            for child in self.list_frame.winfo_children():
                child.destroy()
            self.block_frames = {}
            self.status_frames = {}

            for entry in self.entries:
                frame, status_frame = self._build_block(entry)
                self.block_frames[entry["id"]] = frame
                self.status_frames[entry["id"]] = status_frame

        def _build_block(self, entry: dict) -> tuple[tk.Frame, tk.Frame]:
            entry_id = entry["id"]
            frame = tk.Frame(self.list_frame, bd=1, relief="solid", bg="#ffffff")

            inner = tk.Frame(frame, bg="#ffffff", padx=12, pady=10)
            inner.pack(fill="x")

            tk.Label(inner, text=entry_id, font=("", 10, "bold"), anchor="w", bg="#ffffff", fg="#1a3a8f").pack(fill="x")

            meta = (
                f"{DOMAIN_LABELS.get(entry.get('linh_vuc'), entry.get('linh_vuc'))}  •  "
                f"{PHAN_LOAI_LABELS.get(entry.get('phan_loai'), entry.get('phan_loai'))}  •  "
                f"{entry.get('do_tuoi_thang_min')}-{entry.get('do_tuoi_thang_max')} tháng  •  "
                f"nguồn: {entry.get('_source_file', '')}"
            )
            tk.Label(inner, text=meta, anchor="w", fg="#555", bg="#ffffff").pack(fill="x", pady=(2, 8))

            tk.Label(
                inner, text=entry.get("content", ""), anchor="w", justify="left",
                wraplength=900, bg="#ffffff",
            ).pack(fill="x")

            status_frame = tk.Frame(inner, bg="#ffffff")
            status_frame.pack(fill="x", pady=(10, 0))

            frame.pack(fill="x", padx=6, pady=4)  # đóng gói ban đầu, _apply_filters sẽ điều chỉnh lại
            self._render_block_status(entry_id, status_frame)
            return frame, status_frame

        def _render_block_status(self, entry_id: str, status_frame: tk.Frame | None = None) -> None:
            if status_frame is None:
                status_frame = self.status_frames[entry_id]
            for w in status_frame.winfo_children():
                w.destroy()

            video = self.videos.get(entry_id)
            if video:
                tk.Label(
                    status_frame, text=f"🎬 Đã có video: {video.get('ten_file_goc', '')}",
                    anchor="w", bg="#ffffff", fg="#1b7a3d",
                ).pack(side="left")
                tk.Button(
                    status_frame, text="Thay video...", command=lambda: self._attach_video(entry_id),
                ).pack(side="left", padx=(12, 0))
                tk.Button(
                    status_frame, text="Gỡ video", fg="#b3261e", command=lambda: self._detach_video(entry_id),
                ).pack(side="left", padx=(6, 0))
            else:
                tk.Button(
                    status_frame, text="Thêm video...", bg="#2f6fed", fg="white",
                    command=lambda: self._attach_video(entry_id),
                ).pack(side="left")

        # -- Lọc: chỉ ẩn/hiện khối đã dựng, không dựng lại -----------------

        def _apply_filters(self) -> None:
            linh_vuc = _code_for_label(DOMAINS, self.filter_domain_var.get())
            phan_loai = _code_for_label(PHAN_LOAI, self.filter_phan_loai_var.get())
            age_label = self.filter_age_var.get()
            age_key = next((k for k, label, _, _ in AGE_BANDS if label == age_label), None)

            shown_ids = {
                e["id"]
                for e in filter_entries(
                    self.entries, self.videos,
                    linh_vuc=linh_vuc, phan_loai=phan_loai, age_band_key=age_key,
                    only_missing_video=self.only_missing_var.get(),
                    search_text=self.search_var.get(),
                )
            }

            visible = 0
            for entry in self.entries:  # giữ đúng thứ tự gốc khi hiện lại
                frame = self.block_frames[entry["id"]]
                if entry["id"] in shown_ids:
                    frame.pack(fill="x", padx=6, pady=4)
                    visible += 1
                else:
                    frame.pack_forget()

            self.status_label.config(text=f"Hiện {visible}/{len(self.entries)} entry")

        # -- Hành động có hộp thoại (KHÔNG gọi trong test) -----------------

        def _prompt_project_root(self) -> None:
            chosen = filedialog.askdirectory(title="Chọn thư mục gốc dự án Flutter IRIS")
            if not chosen:
                return
            self.open_project(Path(chosen))

        def _attach_video(self, entry_id: str) -> None:
            if not self.project_root:
                messagebox.showwarning("Thiếu thư mục dự án", "Hãy chọn thư mục gốc dự án trước.")
                return
            if entry_id in self.videos:
                if not messagebox.askyesno(
                    "Entry đã có video",
                    f"Entry '{entry_id}' đã có video. Thay thế bằng video mới? (video cũ sẽ bị xoá)",
                ):
                    return

            chosen = filedialog.askopenfilename(
                title="Chọn video cho entry này",
                filetypes=[("Video", " ".join(f"*{ext}" for ext in VIDEO_EXTENSIONS)), ("Tất cả file", "*.*")],
            )
            if not chosen:
                return

            error = self.apply_attach(entry_id, Path(chosen))
            if error:
                messagebox.showerror("Lỗi khi gắn video", error)
            else:
                messagebox.showinfo("Thành công", f"Đã gắn video cho entry '{entry_id}'.")

        def _detach_video(self, entry_id: str) -> None:
            if entry_id not in self.videos:
                messagebox.showinfo("Không có video", "Entry này hiện chưa có video để gỡ.")
                return
            if not messagebox.askyesno("Xác nhận gỡ video", f"Gỡ video khỏi entry '{entry_id}'? File thật trên đĩa sẽ bị xoá."):
                return
            error = self.apply_detach(entry_id)
            if error:
                messagebox.showerror("Lỗi khi gỡ video", error)

        def _update_pubspec(self) -> None:
            if not self.project_root:
                messagebox.showwarning("Thiếu thư mục dự án", "Hãy chọn thư mục gốc dự án trước.")
                return
            pubspec_path = self.project_root / "pubspec.yaml"
            if not pubspec_path.exists():
                messagebox.showerror("Không tìm thấy", f"Không tìm thấy {pubspec_path}")
                return

            declared = declared_pubspec_asset_dirs(pubspec_path.read_text(encoding="utf-8"))
            missing = missing_pubspec_asset_dirs(self.videos, declared)
            if not missing:
                messagebox.showinfo("Đã đầy đủ", "pubspec.yaml đã khai báo đủ mọi thư mục video hiện có.")
                return

            preview = "\n".join(f"- {d}/" for d in missing)
            if not messagebox.askyesno(
                "Xác nhận cập nhật pubspec.yaml",
                f"Sẽ thêm {len(missing)} dòng sau vào pubspec.yaml (có backup .bak trước khi ghi):\n\n{preview}",
            ):
                return

            ok, message = update_pubspec_file(pubspec_path, missing)
            if ok:
                messagebox.showinfo("Thành công", message)
            else:
                messagebox.showwarning("Không có gì để cập nhật", message)

        # -- Logic thuần dùng chung cho cả UI thật lẫn test (không hộp thoại) --

        def apply_attach(self, entry_id: str, source_path: Path) -> str | None:
            """Gắn video cho [entry_id] + lưu manifest + cập nhật đúng khối
            đó trên UI (không dựng lại toàn bộ danh sách). Trả về thông báo
            lỗi nếu có, None nếu thành công — gọi trực tiếp được từ test mà
            không cần hộp thoại chọn file nào."""
            entry = self.entries_by_id.get(entry_id)
            if entry is None:
                return f"Không tìm thấy entry '{entry_id}'."
            new_videos, error = attach_video(self.project_root, self.videos, entry, source_path)
            if error:
                return error
            self.videos = new_videos
            save_video_manifest(self.project_root, self.videos)
            self._render_block_status(entry_id)
            self._apply_filters()
            return None

        def apply_detach(self, entry_id: str) -> str | None:
            """Gỡ video khỏi [entry_id] + lưu manifest + cập nhật UI. Trả về
            thông báo lỗi nếu có, None nếu thành công."""
            new_videos, error = detach_video(self.project_root, self.videos, entry_id)
            if error:
                return error
            self.videos = new_videos
            save_video_manifest(self.project_root, self.videos)
            self._render_block_status(entry_id)
            self._apply_filters()
            return None

    return tk, ttk, filedialog, messagebox, VideoManagerApp


def _run_gui() -> None:
    tk, _ttk, _filedialog, _messagebox, VideoManagerApp = build_app_class()
    root = tk.Tk()
    app = VideoManagerApp(root)
    if app.project_root is None:
        app._prompt_project_root()
    root.mainloop()


if __name__ == "__main__":
    _run_gui()
