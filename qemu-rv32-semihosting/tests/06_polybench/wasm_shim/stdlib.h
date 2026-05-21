/* Minimal <stdlib.h> shim for the wasm32 freestanding build of atax.c.
 *
 * clang --target=wasm32 -nostdlib does not ship a <stdlib.h>, but
 * polybench.h #includes it unconditionally. With POLYBENCH_STACK_ARRAYS
 * we never actually call any libc allocator, so we only need to
 * satisfy the include (size_t comes via <stddef.h>, which IS in
 * clang's freestanding set). Placed on the wasm-only include path
 * via a per-target -I in the Makefile. */

#ifndef _POLYBENCH_WASM_STDLIB_SHIM
#define _POLYBENCH_WASM_STDLIB_SHIM

#include <stddef.h>

#endif
