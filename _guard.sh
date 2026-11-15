#!/usr/bin/env bash
# Wspólna bramka dla ćwiczeń, które mogą uszkodzić środowisko gościa.
# Wymagamy POTWIERDZENIA i rozpoznanej pełnej VM (kontener to nie VM).
SEC_LAB_MAGIC='ZNISZCZ-TE-VM'
sec_lab_guard() {
    local name="$1" impact="$2" hint=''
    printf '\n[UWAGA] %s\n[SKUTEK] %s\n' "$name" "$impact" >&2
    local confirmed=0 arg
    for arg in "$@" "${SEC_LAB_ARGS[@]}"; do
        [[ "$arg" == '--zniszcz-te-vm' ]] && confirmed=1
    done
    [[ "${SEC_LAB_CONFIRM:-}" == "$SEC_LAB_MAGIC" ]] && confirmed=1
    if (( ! confirmed )); then
        printf 'ZABLOKOWANO. Użyj --zniszcz-te-vm na jednorazowej VM ze snapshotem.\n' >&2
        return 10
    fi
    if ! command -v systemd-detect-virt >/dev/null 2>&1; then
        echo 'ZABLOKOWANO: brak systemd-detect-virt; nie można potwierdzić, że to VM.' >&2
        return 11
    fi
    # --vm może rozpoznać hypervisor POD kontenerem! Obowiązkowy drugi test.
    if systemd-detect-virt --container >/dev/null 2>&1 || [[ -e /.dockerenv || -e /run/.containerenv ]]; then
        echo 'ZABLOKOWANO: wykryto kontener. Host pod spodem może być VM, ale to nie izoluje jądra.' >&2
        return 11
    fi
    hint="$(systemd-detect-virt --vm 2>/dev/null || true)"
    if [[ -z "$hint" || "$hint" == none ]]; then
        echo 'ZABLOKOWANO: nie wykryto pełnej maszyny wirtualnej (kontener/host nie wystarcza).' >&2
        return 11
    fi
    printf 'Wykryto VM: %s. Przed uruchomieniem upewnij się, że istnieje snapshot.\n' "$hint" >&2
    echo 'Start za 3 sekundy (Ctrl-C anuluje)...' >&2
    sleep 3
}
SEC_LAB_ARGS=("$@")