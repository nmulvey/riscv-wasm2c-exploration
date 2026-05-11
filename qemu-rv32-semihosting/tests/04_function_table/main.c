#include "function_table.wasm.h"
#include <stdio.h>
#include <stdint.h>

int main(int argc, char* argv[]) {
    (void)argc;
    (void)argv;

    printf("Testing WASM function table and indirect calls\n\n");
    
    wasm_rt_init();
    w2c_function__table instance;
    wasm2c_function__table_instantiate(&instance);
    
    printf("Direct function calls:\n");
    printf("  add_one(5) = %lu\n", w2c_function__table_add_one(&instance, 5));
    printf("  multiply_two(7) = %lu\n", w2c_function__table_multiply_two(&instance, 7));
    printf("  square(4) = %lu\n\n", w2c_function__table_square(&instance, 4));
    
    printf("Now testing indirect calls via function table...\n");
    printf("  table[0](5) = %lu\n", w2c_function__table_call_by_index(&instance, 0, 5));
    printf("  table[1](5) = %lu\n", w2c_function__table_call_by_index(&instance, 1, 5));
    printf("  table[2](7) = %lu\n", w2c_function__table_call_by_index(&instance, 2, 7));
    printf("  table[3](7) = %lu\n", w2c_function__table_call_by_index(&instance, 3, 7));
    printf("  table[4](4) = %lu\n\n", w2c_function__table_call_by_index(&instance, 4, 4));
    
    printf("Testing bounds checking...\n");
    uint32_t result = w2c_function__table_call_by_index(&instance, 10, 5);
    if (result == 0) {
        printf("  Out of bounds access correctly returned 0\n\n");
    }
    
    /* Verify correctness */
    int success = 1;
    
    if (w2c_function__table_add_one(&instance, 5) != 6) success = 0;
    if (w2c_function__table_multiply_two(&instance, 7) != 14) success = 0;
    if (w2c_function__table_square(&instance, 4) != 16) success = 0;
    if (w2c_function__table_call_by_index(&instance, 0, 5) != 6) success = 0;
    if (w2c_function__table_call_by_index(&instance, 1, 5) != 15) success = 0;
    if (w2c_function__table_call_by_index(&instance, 2, 7) != 14) success = 0;
    if (w2c_function__table_call_by_index(&instance, 3, 7) != 21) success = 0;
    if (w2c_function__table_call_by_index(&instance, 4, 4) != 16) success = 0;
    if (w2c_function__table_call_by_index(&instance, 10, 5) != 0) success = 0;
    
    wasm2c_function__table_free(&instance);
    wasm_rt_free();
    
    if (success) {
        printf("All tests passed!\n");
        return 0;
    } else {
        printf("Some tests failed.\n");
        return 1;
    }
}
