# TweetNaCl crypto_box Code Size Analysis

## Baseline: Native RV32 Binary

Direct compilation of TweetNaCl crypto_box for bare-metal RV32:

| Metric | Size |
|--------|------|
| `.text` section | 18,510 bytes (0x484e) |
| Full binary | 104 KB |
| Total (text+data+bss) | 21,510 bytes |

**Test:** `build/05_box/05_box`
- Compiles and runs successfully on QEMU RV32
- Performs crypto_box encryption/decryption correctly
- No runtime dependencies beyond newlib

## wasm2c Generated Code Analysis

A trivial WASM module with just memory and a function returning `i32.const 0`:

| Metric | Size |
|--------|------|
| Generated C code | 809 lines |
| File size | 28 KB |

Comparing native TweetNaCl (18.5 KB) to wasm2c minimal wrapper (28 KB) shows the wasm2c runtime generates significant overhead.
