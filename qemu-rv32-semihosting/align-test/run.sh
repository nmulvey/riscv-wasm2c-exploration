#!/usr/bin/env bash
set -u

CC=riscv64-unknown-elf-gcc
OBJDUMP=riscv64-unknown-elf-objdump
ARCH="-march=rv32imac_zicsr -mabi=ilp32"
COMMON="-O2 -nostdlib -nostartfiles -ffreestanding $ARCH -Wl,-T,link.ld"
SRC="align_probe.c semi.c start.S"

build() {
    $CC $COMMON -mstrict-align    $SRC -o probe_strict.elf   && echo "built probe_strict.elf"
    $CC $COMMON -mno-strict-align $SRC -o probe_nostrict.elf && echo "built probe_nostrict.elf"
}

dump() {
    for e in probe_strict.elf probe_nostrict.elf; do
        [ -f "$e" ] || continue
        echo "----- $e : load_i32_optimized -----"
        $OBJDUMP -d "$e" | awk '/<load_i32_optimized>:/{f=1} f{print} /ret/{if(f)exit}'
        echo "  lw : $($OBJDUMP -d "$e" | awk '/<load_i32_optimized>:/{f=1} f{print} /ret/{if(f)exit}' | grep -c '\blw\b')"
        echo "  lbu: $($OBJDUMP -d "$e" | awk '/<load_i32_optimized>:/{f=1} f{print} /ret/{if(f)exit}' | grep -c '\blbu\b')"
        echo
    done
}

run() {
    local elf="$1"
    echo "### tolerant qemu (default: emulates misaligned) ###"
    timeout 15 qemu-system-riscv32 -M virt -bios none -nographic \
        -semihosting-config enable=on,target=native -kernel "$elf"
    echo
    echo "### strict qemu (misaligned=off: should trap) ###"
    timeout 15 qemu-system-riscv32 -M virt -bios none -nographic \
        -cpu rv32,misaligned=off \
        -semihosting-config enable=on,target=native -kernel "$elf"
    echo
}

case "${1:-all}" in
    build) build ;;
    dump)  dump ;;
    all)
        build || exit 1
        echo; dump
        echo "=== running probe_nostrict.elf ==="
        run probe_nostrict.elf
        ;;
    *) echo "usage: $0 [build|dump|all]"; exit 1 ;;
esac
