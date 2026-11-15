#!/usr/bin/env bash
# Cel: zobaczyć skutki lawinowego tworzenia procesów W JEDNORAZOWEJ VM.
# UWAGA: nawet ulimit -u nie chroni niezawodnie roota; nie jest sandboxem.
set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/_guard.sh"
[[ $EUID -ne 0 ]] || { echo 'Nie uruchamiaj fork bomby jako root.' >&2; exit 12; }
sec_lab_guard 'Fork bomb' 'wyczerpanie procesów/pamięci VM; konieczny snapshot' || exit $?
echo "RLIMIT_NPROC=$(ulimit -u); pids.max=$(cat /sys/fs/cgroup/pids.max 2>/dev/null || echo brak)"
echo 'WAŻNE: RLIMIT_NPROC nie jest izolacją ani nie działa dla roota z odpowiednimi uprawnieniami.'
echo 'Do wariantu kontrolowanego użyj scope systemd z TasksMax (opis w docs).'
# Program demonstracyjny celowo nieograniczony. NIE URUCHAMIAĆ podczas smoke testów!
bomba() { bomba | bomba & }
bomba