#include <stdio.h>
#include <stdint.h>

// Forward declarations - we'll get these from the wasm2c generated code
typedef struct w2c_ft w2c_ft;
extern uint32_t w2c_ft_add(w2c_ft* instance, uint32_t a, uint32_t b);
extern uint32_t w2c_ft_subtract(w2c_ft* instance, uint32_t a, uint32_t b);
extern uint32_t w2c_ft_multiply(w2c_ft* instance, uint32_t a, uint32_t b);
extern uint32_t w2c_ft_call_op(w2c_ft* instance, uint32_t op_index, uint32_t a, uint32_t b);
extern void wasm2c_ft_instantiate(w2c_ft* instance);

int main(void) {
    printf("Testing WASM function tables\n");
    
    // Allocate space for the instance - the struct size will be linked from the .o file
    static w2c_ft instance;
    wasm2c_ft_instantiate(&instance);
    
    uint32_t val = w2c_ft_add(&instance, 3, 4);
    if (val != 7) {
        printf("FAIL: Direct add(3, 4) = %lu, expected 7\n", val);
        return 1;
    }
    
    val = w2c_ft_subtract(&instance, 10, 3);
    if (val != 7) {
        printf("FAIL: Direct subtract(10, 3) = %lu, expected 7\n", val);
        return 1;
    }
    
    val = w2c_ft_multiply(&instance, 3, 4);
    if (val != 12) {
        printf("FAIL: Direct multiply(3, 4) = %lu, expected 12\n", val);
        return 1;
    }
    
    val = w2c_ft_call_op(&instance, 0, 5, 6);
    if (val != 11) {
        printf("FAIL: Indirect call_op(0, 5, 6) = %lu, expected 11\n", val);
        return 1;
    }
    
    val = w2c_ft_call_op(&instance, 1, 10, 4);
    if (val != 6) {
        printf("FAIL: Indirect call_op(1, 10, 4) = %lu, expected 6\n", val);
        return 1;
    }
    
    val = w2c_ft_call_op(&instance, 2, 3, 5);
    if (val != 15) {
        printf("FAIL: Indirect call_op(2, 3, 5) = %lu, expected 15\n", val);
        return 1;
    }
    
    uint32_t result1 = w2c_ft_call_op(&instance, 0, 100, 50);
    uint32_t result2 = w2c_ft_call_op(&instance, 1, 100, 50);
    uint32_t result3 = w2c_ft_call_op(&instance, 2, 100, 50);
    
    if (result1 != 150 || result2 != 50 || result3 != 5000) {
        printf("FAIL: Multiple ops test - got (%lu, %lu, %lu), expected (150, 50, 5000)\n",
               result1, result2, result3);
        return 1;
    }
    
    printf("✓ All function_table tests passed\n");
    return 0;
}
