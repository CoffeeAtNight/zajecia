#!/usr/bin/env bash
# Inody: tylko osobny ext4 loop wewnątrz VM, sprzątanie trapem.
set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/_guard.sh"
sec_lab_guard 'Wyczerpanie i-węzłów' 'tylko osobny wolumen laboratoryjny' || exit $?
CEL="${SEC_LAB_INODE_MOUNT:-}"
[[ -n "$CEL" && -d "$CEL" && ! -L "$CEL" ]] || { echo 'Ustaw SEC_LAB_INODE_MOUNT na osobny loop FS.' >&2; exit 2; }
CEL="$(realpath -e -- "$CEL")"
[[ "$CEL" != / ]] && mountpoint -q -- "$CEL" || { echo 'To nie jest osobny FS.' >&2; exit 2; }
SRC="$(findmnt -n -o SOURCE --target "$CEL")"
[[ "$SRC" == /dev/loop* ]] || { echo "Odmowa: źródło $SRC nie jest loop FS." >&2; exit 2; }
LIMIT="${SEC_LAB_INODE_LIMIT:-10000}"
[[ "$LIMIT" =~ ^[0-9]+$ ]] && (( LIMIT >= 1 && LIMIT <= 100000 )) || { echo 'Limit liczby plików musi mieścić się w 1..100000.' >&2; exit 2; }
KAT="$(mktemp -d "$CEL/sec-lab-inody.XXXXXXXX")"
cleanup() { rm -rf -- "$KAT"; echo '[CLEANUP] Usunięto utworzone pliki.'; }
trap cleanup EXIT HUP INT TERM
echo '[PRZED]'; df -h "$CEL"; df -i "$CEL"
licznik=0
while (( licznik < LIMIT )); do
    sub="$KAT/d$((licznik / 500))"
    mkdir -p -- "$sub" || break
    if ! : > "$sub/f$licznik"; then echo '[INFO] Brak możliwości utworzenia kolejnego pliku.'; break; fi
    licznik=$((licznik + 1))
done
echo "[PO] Utworzono $licznik plików"; df -h "$CEL"; df -i "$CEL"
if [[ -t 0 ]]; then read -r -p 'Enter = sprzątanie plików: ' _; fi