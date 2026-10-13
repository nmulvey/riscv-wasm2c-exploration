#include <stdint.h>
#include <stdio.h>

#include "bytes.wasm.h"
#include "toy.wasm.h"

extern void install_trap_vector(void);
extern volatile uint32_t g_trapped;
extern volatile uint32_t g_mcause;
extern volatile uint32_t g_trap_count;

static w2c_toy toy;
static w2c_bytes bm;
static int failures;
static int traps;
static unsigned long init_traps;

static void begin(const char *label) {
    printf("%-22s ", label);
    fflush(stdout);
    g_trapped = 0;
}

static void finish(int match, unsigned long hi, unsigned long lo, int wide) {
    if (g_trapped) {
        traps++;
        printf("TRAP mcause=%lu%s\n", (unsigned long)g_mcause,
               (g_mcause & 0x7fffffff) == 4 ? " (load address misaligned)" : "");
        return;
    }
    if (wide)
        printf("%08lx%08lx ", hi, lo);
    else
        printf("%08lx ", lo);
    printf("%s\n", match ? "ok" : "MISMATCH");
    if (!match) failures++;
}

#define CHECK32(label, test, ref)                                           \
    do {                                                                    \
        begin(label);                                                       \
        uint32_t got_ = (test);                                             \
        int trapped_ = g_trapped;                                           \
        uint32_t want_ = (ref);                                             \
        g_trapped = trapped_;                                               \
        finish(got_ == want_, 0, (unsigned long)got_, 0);                   \
    } while (0)

#define CHECK64(label, test, ref)                                           \
    do {                                                                    \
        begin(label);                                                       \
        uint64_t got_ = (test);                                             \
        int trapped_ = g_trapped;                                           \
        uint64_t want_ = (ref);                                             \
        g_trapped = trapped_;                                               \
        finish(got_ == want_, (unsigned long)(got_ >> 32),                  \
               (unsigned long)(got_ & 0xffffffffu), 1);                     \
    } while (0)

int main(int argc, char *argv[]) {
    (void)argc;
    (void)argv;

    install_trap_vector();
    printf("== toy_align start ==\n");
    wasm_rt_init();
    wasm2c_toy_instantiate(&toy);
    wasm2c_bytes_instantiate(&bm);
    w2c_bytes_fill(&bm);
    w2c_toy_init(&toy);
    init_traps = g_trap_count;
    printf("%-22s %lu traps\n", "init", init_traps);

    CHECK32("A  sum_words", w2c_toy_aSumWords(&toy), w2c_toy_refSumWords(&toy));
    CHECK64("A  sum_dwords", w2c_toy_aSumDwords(&toy), w2c_toy_refSumDwords(&toy));
    CHECK32("A  sum_points", w2c_toy_aSumPoints(&toy), w2c_toy_refSumPoints(&toy));
    CHECK32("D  sum_u32_at(0)", w2c_toy_dSumU32At(&toy, 0), w2c_toy_refSumU32At(&toy, 0));
    CHECK32("D  sum_u32_at(2)", w2c_toy_dSumU32At(&toy, 2), w2c_toy_refSumU32At(&toy, 2));
    CHECK32("M  sum_u32_off2", w2c_toy_mSumU32Off2(&toy), w2c_toy_refSumU32At(&toy, 2));
    CHECK64("M  sum_u64_off3", w2c_toy_mSumU64Off3(&toy), w2c_toy_refSumU64Off3(&toy));
    CHECK32("M  sum_packed", w2c_toy_mSumPacked(&toy), w2c_toy_refSumPacked(&toy));
    CHECK32("S  src_byteloop(0)", w2c_toy_sSumByteLoop(&toy, 0), w2c_toy_refSumU32At(&toy, 0));
    CHECK32("S  src_byteloop(2)", w2c_toy_sSumByteLoop(&toy, 2), w2c_toy_refSumU32At(&toy, 2));
    CHECK32("W  wat_bytes(0)", w2c_bytes_sumBytes(&bm, 0), w2c_toy_refSumU32At(&toy, 0));
    CHECK32("W  wat_bytes(1)", w2c_bytes_sumBytes(&bm, 1), w2c_toy_refSumU32At(&toy, 1));
    CHECK32("W  wat_bytes(2)", w2c_bytes_sumBytes(&bm, 2), w2c_toy_refSumU32At(&toy, 2));

    printf("== done: %lu init traps, %d tests trapped, %d mismatched ==\n", init_traps, traps, failures);
    if (init_traps || traps || failures) {
        fprintf(stderr, "ERROR: %lu init traps, %d tests trapped, %d mismatched\n", init_traps, traps, failures);
        return 1;
    }
    return 0;
}
