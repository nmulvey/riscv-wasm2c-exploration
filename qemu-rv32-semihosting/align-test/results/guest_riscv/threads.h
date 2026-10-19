#ifndef STUB_THREADS_H
#define STUB_THREADS_H
#ifndef thread_local
#define thread_local _Thread_local
#endif
typedef struct { int unused; } mtx_t;
enum { mtx_plain = 0, thrd_success = 0 };
static inline int  mtx_init(mtx_t *m, int t) { (void)m; (void)t; return 0; }
static inline int  mtx_lock(mtx_t *m)        { (void)m; return 0; }
static inline int  mtx_unlock(mtx_t *m)      { (void)m; return 0; }
static inline void mtx_destroy(mtx_t *m)     { (void)m; }
#endif
