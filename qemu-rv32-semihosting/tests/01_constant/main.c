#include <stdio.h>
#include <wasm-rt.h>

#include "constant.wasm.h" // Auto-generated

int main(int argc, char* argv[]) {
    (void)argc;
    (void)argv;
    printf("Starting wasm2c test\n");
    wasm_rt_init();
    printf("runtime init done\n");
    w2c_constant instance;
    wasm2c_constant_instantiate(&instance);
    printf("instantiate done\n");
    uint32_t result = w2c_constant_get_value(&instance);
    printf("wasm2c result: %lu\n", result);
    wasm2c_constant_free(&instance);
    wasm_rt_free();
}
