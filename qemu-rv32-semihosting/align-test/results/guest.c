#include <stdint.h>

__attribute__((noinline))
uint32_t load_u32_ptr(const uint32_t *a) { return *a; }

__attribute__((noinline))
uint32_t load_u32_bytes(const uint8_t *a) {
    return (uint32_t)a[0] | ((uint32_t)a[1] << 8) |
           ((uint32_t)a[2] << 16) | ((uint32_t)a[3] << 24);
}
