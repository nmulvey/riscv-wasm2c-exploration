#include <stdio.h>
#include <stdint.h>

extern uint32_t w2c_function_table_add(uint32_t a, uint32_t b);
extern uint32_t w2c_function_table_subtract(uint32_t a, uint32_t b);
extern uint32_t w2c_function_table_multiply(uint32_t a, uint32_t b);
extern uint32_t w2c_function_table_call_op(uint32_t op_index, uint32_t a, uint32_t b);

int main(void) {
    printf("Testing WASM function tables\n");
    
    uint32_t val = w2c_function_table_add(3, 4);
    if (val != 7) {
        printf("FAIL: Direct add(3, 4) = %lu, expected 7\n", val);
        return 1;
    }
    
    val = w2c_function_table_subtract(10, 3);
    if (val != 7) {
        printf("FAIL: Direct subtract(10, 3) = %lu, expected 7\n", val);
        return 1;
    }
    
    val = w2c_function_table_multiply(3, 4);
    if (val != 12) {
        printf("FAIL: Direct multiply(3, 4) = %lu, expected 12\n", val);
        return 1;
    }
    
    val = w2c_function_table_call_op(0, 5, 6);
    if (val != 11) {
        printf("FAIL: Indirect call_op(0, 5, 6) = %lu, expected 11\n", val);
        return 1;
    }
    
    val = w2c_function_table_call_op(1, 10, 4);
    if (val != 6) {
        printf("FAIL: Indirect call_op(1, 10, 4) = %lu, expected 6\n", val);
        return 1;
    }
    
    val = w2c_function_table_call_op(2, 3, 5);
    if (val != 15) {
        printf("FAIL: Indirect call_op(2, 3, 5) = %lu, expected 15\n", val);
        return 1;
    }
    
    uint32_t result1 = w2c_function_table_call_op(0, 100, 50);
    uint32_t result2 = w2c_function_table_call_op(1, 100, 50);
    uint32_t result3 = w2c_function_table_call_op(2, 100, 50);
    
    if (result1 != 150 || result2 != 50 || result3 != 5000) {
        printf("FAIL: Multiple ops test - got (%lu, %lu, %lu), expected (150, 50, 5000)\n",
               result1, result2, result3);
        return 1;
    }
    
    printf("✓ All function_table tests passed\n");
    return 0;
}
