#!/usr/bin/env python3
"""Wyczerpanie pamięci: tryb limitowany oraz świadome demo OOM w VM."""
import argparse
import os
import subprocess
import sys
import time


def ensure_vm():
    if not (os.environ.get("SEC_LAB_CONFIRM") == "ZNISZCZ-TE-VM" or "--zniszcz-te-vm" in sys.argv):
        sys.exit("Brak potwierdzenia --zniszcz-te-vm; użyj --limit-mib 128 do testu ograniczonego.")
    try:
        p = subprocess.run(["systemd-detect-virt", "--vm"], capture_output=True, text=True, check=False)
    except FileNotFoundError:
        sys.exit("Nie można potwierdzić VM: brak systemd-detect-virt.")
    container = subprocess.run(["systemd-detect-virt", "--container"], capture_output=True, check=False)
    if container.returncode == 0 or os.path.exists("/.dockerenv") or os.path.exists("/run/.containerenv"):
        sys.exit("Wykryto kontener. --vm może wykrywać wirtualizację POD kontenerem; odmowa.")
    if p.returncode or p.stdout.strip() in {"", "none"}:
        sys.exit("Nie można potwierdzić pełnej VM. Przerwano.")
    print("Potwierdzona VM; start za 3 s. Przygotuj snapshot.", file=sys.stderr, flush=True)
    time.sleep(3)


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    mode = ap.add_mutually_exclusive_group(required=True)
    mode.add_argument("--limit-mib", type=int, help="ograniczony eksperyment bez OOM (16-512 MiB)")
    mode.add_argument("--zniszcz-te-vm", action="store_true", help="pełne OOM — tylko VM")
    args = ap.parse_args()
    if args.limit_mib is not None and not 16 <= args.limit_mib <= 512:
        ap.error("--limit-mib musi mieścić się w 16..512")