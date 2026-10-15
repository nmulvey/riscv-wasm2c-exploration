#!/usr/bin/env bash
set -u
CC=riscv64-unknown-elf-gcc
OBJDUMP=riscv64-unknown-elf-objdump
ARCH="-march=rv32imac_zicsr -mabi=ilp32"
COMMON="-O2 -nostdlib -nostartfiles -ffreestanding -I stub $ARCH -Wl,-T,link.ld"
SRC="align_probe_defensive.c semi.c start.S"

build() {
  $CC $COMMON -mstrict-align                       $SRC -o def_strict.elf       && echo "built def_strict.elf"
  $CC $COMMON -mno-strict-align                    $SRC -o def_nostrict.elf     && echo "built def_nostrict.elf"
  $CC $COMMON -mno-strict-align -mtune=generic-ooo $SRC -o def_nostrict_ooo.elf && echo "built def_nostrict_ooo.elf"
}

fn() { $OBJDUMP -d "$1" | awk '/<load_i32_defensive>:/{f=1} f{print} /ret/{if(f)exit}'; }

dump() {
  for e in def_strict.elf def_nostrict.elf def_nostrict_ooo.elf; do
    [ -f "$e" ] || continue
    echo "----- $e : load_i32_defensive -----"
    fn "$e"
    echo "  lw: $(fn "$e" | grep -c '\blw\b')   lbu: $(fn "$e" | grep -c '\blbu\b')"
    echo
  done
}

run() {
  for e in def_nostrict.elf def_nostrict_ooo.elf; do
    echo "### strict qemu (misaligned=off): $e ###"
    timeout 15 qemu-system-riscv32 -M virt -bios none -nographic -cpu rv32,misaligned=off \
      -semihosting-config enable=on,target=native -kernel "$e"
    echo
  done
}

case "${1:-all}" in
  build) build ;;
  dump)  dump ;;
  run)   run ;;
  all)   build || exit 1; echo; dump ;;
esac
