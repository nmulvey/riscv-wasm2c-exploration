#include <stdio.h>
#include <stdint.h>

extern uint32_t w2c_global_get_counter(void);
extern void w2c_global_increment_counter(void);
extern void w2c_global_set_counter(uint32_t value);

int main(void) {
    printf("Hello from global test\n");
    printf("About to call w2c_global_get_counter\n");
    
    uint32_t val = w2c_global_get_counter();
    
    printf("Got value: %lu\n", val);
    printf("Test completed\n");
    return 0;
}
