#include "memory.wasm.h"
#include <stdint.h>
#include <stdio.h>

int main(int argc, char* argv[]) {
    (void)argc;
    (void)argv;

    printf("Testing WASM linear memory\n");
    wasm_rt_init();

    w2c_memory instance;
    wasm2c_memory_instantiate(&instance);

    w2c_memory_write_byte(&instance, 0, 42);
    uint32_t val = w2c_memory_read_byte(&instance, 0);
    if (val != 42) {
        printf("FAIL: Byte test - wrote 42, read %lu\n", val);
        return 1;
    }

    w2c_memory_write_int(&instance, 4, 0xDEADBEEF);
    val = w2c_memory_read_int(&instance, 4);
    if (val != 0xDEADBEEF) {
        printf("FAIL: Int test - wrote 0xDEADBEEF, read 0x%lx\n", val);
        return 1;
    }

    w2c_memory_write_byte(&instance, 10, 0x11);
    w2c_memory_write_byte(&instance, 11, 0x22);
    w2c_memory_write_byte(&instance, 12, 0x33);

    val = w2c_memory_read_byte(&instance, 10);
    if (val != 0x11) {
        printf("FAIL: Byte at offset 10 - wrote 0x11, read 0x%lx\n", val);
        return 1;
    }

    val = w2c_memory_read_byte(&instance, 11);
    if (val != 0x22) {
        printf("FAIL: Byte at offset 11 - wrote 0x22, read 0x%lx\n", val);
        return 1;
    }

    val = w2c_memory_read_byte(&instance, 12);
    if (val != 0x33) {
        printf("FAIL: Byte at offset 12 - wrote 0x33, read 0x%lx\n", val);
        return 1;
    }

    w2c_memory_write_int(&instance, 20, 0x04030201);

    val = w2c_memory_read_byte(&instance, 20);
    if (val != 0x01) {
        printf("FAIL: First byte of int - expected 0x01, got 0x%lx\n", val);
        return 1;
    }

    val = w2c_memory_read_byte(&instance, 21);
    if (val != 0x02) {
        printf("FAIL: Second byte of int - expected 0x02, got 0x%lx\n", val);
        return 1;
    }

    wasm2c_memory_free(&instance);
    wasm_rt_free();

    printf("All memory tests passed\n");
    return 0;
}
