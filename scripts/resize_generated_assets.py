"""Downsize generated PNG assets for predictable mobile memory usage."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("paths", nargs="+", type=Path)
    parser.add_argument("--max-edge", required=True, type=int)
    args = parser.parse_args()

    for path in args.paths:
        image = Image.open(path).convert("RGBA")
        image.thumbnail((args.max_edge, args.max_edge), Image.Resampling.LANCZOS)
        image.save(path, optimize=True)


if __name__ == "__main__":
    main()
