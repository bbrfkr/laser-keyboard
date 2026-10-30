#!/usr/bin/env python3
"""JLCPCB の配置データ（CPL）を、KiCad の PCB から補正込みで作る。

kicad-cli で PCB の配置（ドリル原点基準・mm・両面）を出し、
bom.csv（JLCPCB に実装を頼む部品）に載っている部品だけを残して、jlc-cpl-offsets.csv の補正を足す。
回路図の LCSC 欄では絞らない（キースイッチのソケットは LCSC 番号を持つが、JLCPCB には頼まない）。
補正は JLCPCB の部品データと KiCad のフットプリントで基準点・向きが違う部品のためのもので、
出力の座標系（Mid X・Mid Y・Rotation）でそのまま足す。

使い方:
  python scripts/make-jlc-cpl.py                 # pos.csv を書き直す
  python scripts/make-jlc-cpl.py -o out.csv      # 別のファイルへ書く
  python scripts/make-jlc-cpl.py -o out.csv && git diff --no-index pos.csv out.csv

kicad-cli は --kicad-cli、環境変数 KICAD_CLI、PATH、既定のインストール先の順で探す。
"""

import argparse
import csv
import glob
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PCB = os.path.join(ROOT, "laser-keyboard.kicad_pcb")
BOM = os.path.join(ROOT, "bom.csv")
OFFSETS = os.path.join(ROOT, "jlc-cpl-offsets.csv")


def find_kicad_cli(explicit):
    candidates = [explicit, os.environ.get("KICAD_CLI"), shutil.which("kicad-cli")]
    for base in (os.path.join(os.environ.get("LOCALAPPDATA", ""), "Programs"), os.environ.get("ProgramFiles", "")):
        if base:
            candidates += sorted(glob.glob(os.path.join(base, "KiCad", "*", "bin", "kicad-cli.exe")), reverse=True)
    candidates.append("/Applications/KiCad/KiCad.app/Contents/MacOS/kicad-cli")
    for c in candidates:
        if c and os.path.isfile(c):
            return c
    sys.exit("kicad-cli が見つからない。--kicad-cli か環境変数 KICAD_CLI で指定する")


def run(cli, *args):
    subprocess.run([cli, *args], check=True, stdout=subprocess.DEVNULL)


def read_csv(path):
    with open(path, encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def fmt(value):
    text = f"{value:.6f}".rstrip("0").rstrip(".")
    return "0" if text == "-0" else text


def normalize(angle):
    # KiCad の出力に合わせ、(-180, 180] に収める
    angle %= 360
    return angle - 360 if angle > 180 else angle


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("-o", "--output", default=os.path.join(ROOT, "pos.csv"))
    parser.add_argument("--offsets", default=OFFSETS)
    parser.add_argument("--kicad-cli")
    args = parser.parse_args()

    cli = find_kicad_cli(args.kicad_cli)
    with tempfile.TemporaryDirectory() as tmp:
        pos_path = os.path.join(tmp, "pos.csv")
        run(cli, "pcb", "export", "pos", PCB, "--format", "csv", "--units", "mm",
            "--side", "both", "--use-drill-file-origin", "-o", pos_path)
        placements = read_csv(pos_path)

    wanted = {d.strip() for r in read_csv(BOM) for d in r["Designator"].split(",")}
    missing = wanted - {p["Ref"] for p in placements}
    if missing:
        sys.exit(f"bom.csv に在るが PCB に無い部品: {', '.join(sorted(missing))}")
    offsets = {r["Designator"]: r for r in read_csv(args.offsets)}
    rows = []
    for p in placements:
        ref = p["Ref"]
        if ref not in wanted:
            continue
        o = offsets.pop(ref, {"dX": 0, "dY": 0, "dRotation": 0})
        rows.append([
            ref,
            fmt(float(p["PosX"]) + float(o["dX"])),
            fmt(float(p["PosY"]) + float(o["dY"])),
            fmt(normalize(float(p["Rot"]) + float(o["dRotation"]))),
            p["Side"],
        ])
    if offsets:
        sys.exit(f"補正の表に、配置データに無い部品が在る: {', '.join(offsets)}")

    with open(args.output, "w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f, lineterminator="\r\n")
        writer.writerow(["Designator", "Mid X", "Mid Y", "Rotation", "Layer"])
        writer.writerows(rows)
    print(f"{len(rows)} 部品を {args.output} に書いた")


if __name__ == "__main__":
    main()
