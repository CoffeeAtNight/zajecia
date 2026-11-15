#!/usr/bin/env bash
# ENOSPC demonstrujemy tylko na OSOBNYM wolumenie loop w gościu VM.
set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/_guard.sh"
sec_lab_guard 'ENOSPC' 'zapełnienie WYŁĄCZNIE osobnego wolumenu laboratoryjnego' || exit $?
CEL="${SEC_LAB_FILL_TARGET:-}"
[[ -n "$CEL" && -d "$CEL" && ! -L "$CEL" ]] || { echo 'Ustaw SEC_LAB_FILL_TARGET na zamontowany osobny ext4 loop FS.' >&2; exit 2; }
CEL="$(realpath -e -- "$CEL")"
[[ "$CEL" != / && "$CEL" != /home && "$CEL" != /var ]] || { echo 'Odmowa pracy na partycji systemowej.' >&2; exit 2; }
mountpoint -q -- "$CEL" || { echo 'To nie jest osobny punkt montowania.' >&2; exit 2; }
SRC="$(findmnt -n -o SOURCE --target "$CEL")"
[[ "$SRC" == /dev/loop* ]] || { echo "Odmowa: źródło $SRC nie jest urządzeniem loop." >&2; exit 2; }
PLIK="$(mktemp "$CEL/.sec-lab-blocks.XXXXXXXX")"
cleanup() { rm -f -- "$PLIK"; echo '[CLEANUP] Usunięto plik rezerwujący bloki.'; }
trap cleanup EXIT HUP INT TERM
WOLNE_KB="$(df -Pk -- "$CEL" | awk 'NR==2{print $4}')"
(( WOLNE_KB > 2048 )) || { echo 'Za mało wolnego miejsca w laboratorium.' >&2; exit 2; }
ROZMIAR_KB=$((WOLNE_KB - 1024))
echo '[PRZED]'; df -h "$CEL"
echo "[DZIAŁANIE] fallocate ${ROZMIAR_KB}KiB na wolumenie $SRC"
fallocate -l "${ROZMIAR_KB}K" "$PLIK"
echo '[PO]'; df -h "$CEL"
echo '[TEST] Czy zapis w wolumenie jeszcze działa? (może pozostać margines 1 MiB)'
if [[ -t 0 ]]; then read -r -p 'Enter = sprzątanie i zwolnienie bloków: ' _; fi