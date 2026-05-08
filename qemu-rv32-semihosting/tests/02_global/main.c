#include <stdio.h>

extern uint32_t w2c_get_counter(void);
extern void w2c_increment_counter(void);
extern void w2c_set_counter(uint32_t value);

int main(void) {
    printf("Testing WASM global variables\n");
    
    uint32_t val = w2c_get_counter();
    if (val != 0) {
        printf("FAIL: Initial value is %u, expected 0\n", val);
        return 1;
    }
    
    w2c_increment_counter();
    val = w2c_get_counter();
    if (val != 1) {
        printf("FAIL: After increment, value is %u, expected 1\n", val);
        return 1;
    }
    
    w2c_set_counter(42);
    val = w2c_get_counter();
    if (val != 42) {
        printf("FAIL: After set_counter(42), value is %u, expected 42\n", val);
        return 1;
    }
    
    w2c_increment_counter();
    w2c_increment_counter();
    val = w2c_get_counter();
    if (val != 44) {
        printf("FAIL: After 2 increments from 42, value is %u, expected 44\n", val);
        return 1;
    }
    
    printf("✓ All global tests passed\n");
    return 0;
}
