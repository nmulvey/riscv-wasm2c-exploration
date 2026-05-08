#include <stdio.h>
#include <stdint.h>

extern void w2c_write_byte(uint32_t offset, uint32_t value);
extern uint32_t w2c_read_byte(uint32_t offset);
extern void w2c_write_int(uint32_t offset, uint32_t value);
extern uint32_t w2c_read_int(uint32_t offset);

int main(void) {
    printf("Testing WASM linear memory\n");
    
    w2c_write_byte(0, 42);
    uint32_t val = w2c_read_byte(0);
    if (val != 42) {
        printf("FAIL: Byte test - wrote 42, read %lu\n", val);
        return 1;
    }
    
    w2c_write_int(4, 0xDEADBEEF);
    val = w2c_read_int(4);
    if (val != 0xDEADBEEF) {
        printf("FAIL: Int test - wrote 0xDEADBEEF, read 0x%lx\n", val);
        return 1;
    }
    
    w2c_write_byte(10, 0x11);
    w2c_write_byte(11, 0x22);
    w2c_write_byte(12, 0x33);
    
    val = w2c_read_byte(10);
    if (val != 0x11) {
        printf("FAIL: Byte at offset 10 - wrote 0x11, read 0x%lx\n", val);
        return 1;
    }
    
    val = w2c_read_byte(11);
    if (val != 0x22) {
        printf("FAIL: Byte at offset 11 - wrote 0x22, read 0x%lx\n", val);
        return 1;
    }
    
    val = w2c_read_byte(12);
    if (val != 0x33) {
        printf("FAIL: Byte at offset 12 - wrote 0x33, read 0x%lx\n", val);
        return 1;
    }
    
    w2c_write_int(20, 0x04030201);
    
    val = w2c_read_byte(20);
    if (val != 0x01) {
        printf("FAIL: First byte of int - expected 0x01, got 0x%lx\n", val);
        return 1;
    }
    
    val = w2c_read_byte(21);
    if (val != 0x02) {
        printf("FAIL: Second byte of int - expected 0x02, got 0x%lx\n", val);
        return 1;
    }
    
    printf("✓ All memory tests passed\n");
    return 0;
}
