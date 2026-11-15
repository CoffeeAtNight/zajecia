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
