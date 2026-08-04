#!/usr/bin/env bash
set -u

progs=(
  "05_box:05_box_wasm:tests/05_box/expected_wasm.txt"
  "06_polybench:06_polybench_atax_wasm:tests/06_polybench/expected_atax_wasm.txt"
  "06_polybench:06_polybench_gemm_wasm:"
  "06_polybench:06_polybench_mm2_wasm:"
  "06_polybench:06_polybench_mm3_wasm:"
  "06_polybench:06_polybench_mvt_wasm:"
)

if [ "$#" -gt 0 ]; then
  keep=()
  for e in "${progs[@]}"; do
    for w in "$@"; do [[ "$e" == *"$w"* ]] && keep+=("$e") && break; done
  done
  progs=("${keep[@]}")
fi

qemu="qemu-system-riscv32 -machine virt -bios none -nographic -semihosting"
SIZE=$(command -v riscv32-none-elf-size || command -v size || command -v llvm-size)
mkdir -p results
ts=$(date +%H%M%S)
tsv="results/summary-$ts.tsv"
printf "prog\tvariant\truns\toutput\tcycles\ttext\n" > "$tsv"

if [ "${CROSS:-0}" = "1" ]; then
  variants=("baseline:ASSUME_ALIGNED=0:NO_STRICT_ALIGN=0" "aligned:ASSUME_ALIGNED=1:NO_STRICT_ALIGN=0" "flag:ASSUME_ALIGNED=0:NO_STRICT_ALIGN=1" "both:ASSUME_ALIGNED=1:NO_STRICT_ALIGN=1")
else
  variants=("baseline:ASSUME_ALIGNED=0:NO_STRICT_ALIGN=0" "aligned:ASSUME_ALIGNED=1:NO_STRICT_ALIGN=0")
fi

cycles() { grep -i cycles "$1" 2>/dev/null | grep -oE '[0-9]+' | tail -1; }
fprint() { grep -i fingerprint "$1" 2>/dev/null | grep -oE '[0-9]+' | tail -1; }
text() { "$SIZE" "$1" 2>/dev/null | awk 'NR==2{print $1}'; }
pct() {
  [ -z "$1" ] || [ -z "$2" ] || [ "$1" -eq 0 ] 2>/dev/null && { echo n/a; return; }
  awk -v b="$1" -v n="$2" 'BEGIN{printf "%+.1f%%",(n-b)/b*100}'
}

printf "%-14s %-9s %-6s %-9s %14s %11s\n" prog variant runs output cycles text
for e in "${progs[@]}"; do
  IFS=':' read -r dir elf exp <<< "$e"
  name="${elf#06_polybench_}"; name="${name%_wasm}"; name="${name/05_box_wasm/box}"
  t="build/$dir/$elf"
  declare -A cy=() tx=() fp=()

  for v in "${variants[@]}"; do
    IFS=':' read -r vn aa sa <<< "$v"
    log="results/${name}-${vn}-${ts}.run"
    make clean >/dev/null 2>&1

    if ! make "$t" BENCH=1 "$aa" "$sa" >"results/${name}-${vn}-${ts}.build" 2>&1; then
      printf "%-14s %-9s %-6s %-9s %14s %11s\n" "$name" "$vn" FAIL - - -
      printf "%s\t%s\tFAIL\t-\t-\t-\n" "$name" "$vn" >> "$tsv"
      continue
    fi

    $qemu -kernel "$t" >"$log" 2>&1 &
    p=$!
    ( sleep 60; kill -9 $p 2>/dev/null ) 2>/dev/null &
    w=$!
    wait $p 2>/dev/null; rc=$?
    kill -9 $w 2>/dev/null; wait $w 2>/dev/null

    c=$(cycles "$log"); x=$(text "$t"); f=$(fprint "$log")
    cy[$vn]=$c; tx[$vn]=$x; fp[$vn]=$f

    if [ "$rc" -ne 0 ] && [ -z "$c" ]; then
      runs=TRAP; out=-
    else
      runs=ok
      if [ -n "$exp" ] && [ -f "$exp" ]; then
        if diff -q <(grep -viE 'cycle|instret' "$log") "$exp" >/dev/null 2>&1; then out=match; else out=MISMATCH; fi
      elif grep -qi pass "$log"; then
        out=PASS
      else
        out=noref
      fi
    fi
    printf "%-14s %-9s %-6s %-9s %14s %11s\n" "$name" "$vn" "$runs" "$out" "${c:--}" "${x:--}"
    printf "%s\t%s\t%s\t%s\t%s\t%s\n" "$name" "$vn" "$runs" "$out" "${c:--}" "${x:--}" >> "$tsv"
  done

  if [ -n "${fp[baseline]:-}" ] && [ -n "${fp[aligned]:-}" ]; then
    if [ "${fp[baseline]}" = "${fp[aligned]}" ]; then fpnote="fp ok"; else fpnote="fp DIFFERS"; fi
  else fpnote=""; fi

  [ -n "${cy[baseline]:-}" ] && [ -n "${cy[aligned]:-}" ] && \
    printf "  -> cyc %s  text %s  %s\n" "$(pct "${cy[baseline]}" "${cy[aligned]}")" "$(pct "${tx[baseline]:-0}" "${tx[aligned]:-0}")" "$fpnote"
done

echo
echo "table: $tsv"
echo "TRAP = aligned faulted (bad hint). MISMATCH = wrong vs reference. fp DIFFERS = aligned changed the computed result."
