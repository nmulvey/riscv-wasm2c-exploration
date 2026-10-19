| Build | load_i32_defensive | Offsets 1-3 |
|---|---|---|
| GCC, -mstrict-align | 4x lbu, assembled on stack, lw 12(sp) | safe |
| GCC, -mno-strict-align | 4x lbu, assembled on stack, lw 12(sp) | safe |
| GCC, -mno-strict-align -mtune=generic-ooo | lw 0(a5) | misaligned lw |
| clang, -mno-strict-align | lw 0(a0) | misaligned lw |

| Stage | load_u32_ptr | load_u32_bytes |
|---|---|---|
| Wasm | i32.load (align=4) | i32.load align=1 |
| wasm2c | i32_load(...) | i32_load(...) |

| Build | load_u32_ptr | load_u32_bytes |
|---|---|---|
| strict | 4x lbu | 4x lbu |
| -mno-strict-align | 4x lbu | 4x lbu |
| -mno-strict-align -mtune=generic-ooo | lw a0,0(a4) | lw a0,0(a4) |
