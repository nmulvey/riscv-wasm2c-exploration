// FOCUS: w2c_loadptr_do_load
// NATIVE_FOCUS: do_load
//
// Smallest interesting case: a single load through a caller-supplied
// pointer. In the wasm2c-generated C the pointer is a wasm linear-memory
// offset, so `*p` lowers to an explicit bounds check (BOUNDS_CHECK mode is
// forced on our 32-bit targets; guard pages are unavailable) followed by an
// unchecked load, wrapped in wasm2c's call-stack-depth guard.
//
// wasm2c names a leaf export's body after the export itself
// (`w2c_loadptr_do_load`); the `_<n>` suffixed bodies only appear for
// functions that are also called internally. The FOCUS marker pins the
// exact symbol so the driver never has to guess.

#include <stdint.h>

uint32_t do_load(const uint32_t* p) { return *p; }
