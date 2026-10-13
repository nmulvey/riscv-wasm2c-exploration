#include <stdint.h>
#include <string.h>

extern long semi_call(long reason, void *arg);

void semi_puts(const char *s) {
    semi_call(0x04, (void *)s);
}

void semi_puthex(uint32_t v) {
    static const char hexd[] = "0123456789abcdef";
    char buf[11];
    buf[0] = '0'; buf[1] = 'x';
    for (int i = 0; i < 8; i++)
        buf[2 + i] = hexd[(v >> ((7 - i) * 4)) & 0xF];
    buf[10] = '\0';
    semi_puts(buf);
}

void report_trap(uint32_t mcause) {
    semi_puts("\ntrap! mcause=");
    semi_puthex(mcause);
    switch (mcause & 0x7fffffff) {
        case 4: semi_puts("  load address misaligned\n"); break;
        case 5: semi_puts("  load access fault\n"); break;
        case 6: semi_puts("  store address misaligned\n"); break;
        case 7: semi_puts("  store access fault\n"); break;
        default: semi_puts("  other\n"); break;
    }
    uint32_t block[2] = {0x20023, 1};
    semi_call(0x18, block);
}
