#include "global.wasm.h"
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>

int main(int argc, char* argv[]) {
    (void)argc;
    (void)argv;

    printf("Testing WASM global variables\n");
    wasm_rt_init();

    w2c_global instance;
    wasm2c_global_instantiate(&instance);

    uint32_t val = w2c_global_get_counter(&instance);
    if (val != 0) {
        printf("FAIL: Initial value is %" PRIu32 ", expected 0\n", val);
        return 1;
    }

    w2c_global_increment_counter(&instance);
    val = w2c_global_get_counter(&instance);
    if (val != 1) {
        printf("FAIL: After increment, value is %" PRIu32 ", expected 1\n", val);
        return 1;
    }

    w2c_global_set_counter(&instance, 42);
    val = w2c_global_get_counter(&instance);
    if (val != 42) {
        printf("FAIL: After set_counter(42), value is %" PRIu32 ", expected 42\n", val);
        return 1;
    }

    w2c_global_increment_counter(&instance);
    w2c_global_increment_counter(&instance);
    val = w2c_global_get_counter(&instance);
    if (val != 44) {
        printf("FAIL: After 2 increments from 42, value is %" PRIu32 ", expected 44\n", val);
        return 1;
    }

    wasm2c_global_free(&instance);
    wasm_rt_free();

    printf("All global tests passed\n");
    return 0;
}
