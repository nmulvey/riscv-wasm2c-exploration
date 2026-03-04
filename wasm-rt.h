#ifndef WASM_RT_H
#define WASM_RT_H
typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
typedef unsigned int uint32_t;
typedef unsigned long long uint64_t;
typedef signed int int32_t;
typedef signed long long int64_t;
typedef unsigned int bool;
typedef const void* wasm_rt_func_type_t;
typedef struct { uint8_t *data; uint8_t *data_end; uint64_t size; uint64_t pages; uint64_t max_pages; uint32_t page_size; } wasm_rt_memory_t;
#define WASM_RT_THREAD_LOCAL
#define LIKELY(x) (x)
#define UNLIKELY(x) (x)
#define WASM_RT_NO_TSAN
typedef enum { WASM_RT_TRAP_OOB, WASM_RT_TRAP_INT_OVERFLOW, WASM_RT_TRAP_DIV_BY_ZERO, WASM_RT_TRAP_INVALID_CONVERSION, WASM_RT_TRAP_UNREACHABLE, WASM_RT_TRAP_CALL_INDIRECT, WASM_RT_TRAP_EXHAUSTION, WASM_RT_TRAP_SHADOW_STACK_EXHAUSTION } wasm_rt_trap_t;
static void wasm_rt_trap(wasm_rt_trap_t x) { (void)x; }
static void wasm_rt_memcpy(void *d, const void *s, uint32_t n) { uint8_t *dd = (uint8_t*)d; const uint8_t *ss = (const uint8_t*)s; while(n--) *dd++ = *ss++; }
static int memcmp(const void *a, const void *b, uint32_t n) { const uint8_t *aa = (const uint8_t*)a; const uint8_t *bb = (const uint8_t*)b; while(n--) { if(*aa != *bb) return *aa - *bb; aa++; bb++; } return 0; }
#endif
typedef float f32;
typedef double f64;
static int isnan(f64 x) { return 0; }
static f64 floor(f64 x) { return x; }
static f32 floorf(f32 x) { return x; }
static f64 ceil(f64 x) { return x; }
static f32 ceilf(f32 x) { return x; }
static f64 trunc(f64 x) { return x; }
static f32 truncf(f32 x) { return x; }
static f64 nearbyint(f64 x) { return x; }
static f32 nearbyintf(f32 x) { return x; }
static f32 fabsf(f32 x) { return x < 0 ? -x : x; }
static f64 fabs(f64 x) { return x < 0 ? -x : x; }
static f64 sqrt(f64 x) { return x; }
static f32 sqrtf(f32 x) { return x; }
static void* memset(void *s, int c, uint32_t n) { uint8_t *p = (uint8_t*)s; while(n--) *p++ = c; return s; }
static void* memmove(void *d, const void *s, uint32_t n) { return d; }
typedef void* wasm_rt_function_ptr_t;
typedef void* wasm_rt_tailcallee_t;
typedef void* wasm_rt_funcref_t;
typedef struct { wasm_rt_funcref_t *data; uint32_t size; uint32_t max_size; } wasm_rt_funcref_table_t;
typedef struct { void **data; uint32_t size; uint32_t max_size; } wasm_rt_externref_table_t;
static wasm_rt_funcref_t wasm_rt_funcref_null_value = 0;
static void* wasm_rt_externref_null_value = 0;
typedef void* wasm_rt_externref_t;
#define assert(x) ((void)(x))
static int wasm_rt_is_initialized(void) { return 1; }
#define true 1
#define false 0
typedef enum { WASM_RT_I32, WASM_RT_I64, WASM_RT_F32, WASM_RT_F64, WASM_RT_FUNCREF, WASM_RT_EXTERNREF } wasm_rt_type_t;
#include <stdarg.h>
extern void wasm_rt_bounds_check_failed(void);
#undef MEMCHECK_DEFAULT32
#define MEMCHECK_DEFAULT32(mem, addr, t) \
  if ((addr) + sizeof(t) > (mem)->size) wasm_rt_bounds_check_failed();
