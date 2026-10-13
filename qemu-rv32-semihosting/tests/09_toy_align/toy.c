#include <stdint.h>

#if defined(__wasm__)
#define EXPORT(name) __attribute__((export_name(name), noinline))
#else
#define EXPORT(name) __attribute__((noinline))
#endif

#define NW 64
#define NB (4 * NW + 16)
#define NP 16
#define NH 16

static uint32_t words[NW];
static uint64_t dwords[NW / 2];
static uint8_t bytes[NB] __attribute__((aligned(8)));

struct point {
    uint32_t x, y;
    uint16_t tag, pad;
};
static struct point points[NP];

struct __attribute__((packed)) hdr {
    uint8_t kind;
    uint32_t len;
    uint16_t id;
    uint32_t crc;
};
static struct hdr hdrs[NH];

static inline uint8_t pat8(uint32_t i) { return (uint8_t)(i * 37u + 11u); }
static inline uint32_t pat32(uint32_t i) {
    return (uint32_t)pat8(i) | (uint32_t)pat8(i + 1) << 8 |
           (uint32_t)pat8(i + 2) << 16 | (uint32_t)pat8(i + 3) << 24;
}
static inline uint64_t pat64(uint32_t i) {
    return (uint64_t)pat32(i) | (uint64_t)pat32(i + 4) << 32;
}
static inline uint32_t wval(uint32_t i) { return i * 2654435761u; }
static inline uint64_t dval(uint32_t i) { return (uint64_t)i * 0x9E3779B97F4A7C15ull; }

EXPORT("init") void toy_init(void) {
    for (uint32_t i = 0; i < NW; i++) words[i] = wval(i);
    for (uint32_t i = 0; i < NW / 2; i++) dwords[i] = dval(i);
    for (uint32_t i = 0; i < NB; i++) bytes[i] = pat8(i);
    for (uint32_t i = 0; i < NP; i++) {
        points[i].x = wval(i);
        points[i].y = wval(i + 100);
        points[i].tag = (uint16_t)i;
        points[i].pad = 0;
    }
    for (uint32_t i = 0; i < NH; i++) {
        hdrs[i].kind = (uint8_t)i;
        hdrs[i].len = wval(i + 200);
        hdrs[i].id = (uint16_t)(i * 7);
        hdrs[i].crc = wval(i + 300);
    }
}

EXPORT("aSumWords") uint32_t a_sum_words(void) {
    uint32_t s = 0;
    for (uint32_t i = 0; i < NW; i++) s += words[i];
    return s;
}

EXPORT("aSumDwords") uint64_t a_sum_dwords(void) {
    uint64_t s = 0;
    for (uint32_t i = 0; i < NW / 2; i++) s += dwords[i];
    return s;
}

EXPORT("aSumPoints") uint32_t a_sum_points(void) {
    uint32_t s = 0;
    for (uint32_t i = 0; i < NP; i++) s += (points[i].x ^ points[i].y) + points[i].tag;
    return s;
}

EXPORT("dSumU32At") uint32_t d_sum_u32_at(uint32_t off) {
    if (off > 16) return 0;
    uint32_t s = 0;
    for (uint32_t i = 0; i < NW; i++) {
        uint32_t v;
        __builtin_memcpy(&v, bytes + off + 4 * i, 4);
        s += v;
    }
    return s;
}

EXPORT("sSumByteLoop") uint32_t s_sum_byte_loop(uint32_t off) {
    if (off > 16) return 0;
    uint32_t s = 0;
    for (uint32_t i = 0; i < NW; i++) {
        const uint8_t *p = bytes + off + 4 * i;
        uint32_t v = 0;
        for (uint32_t k = 0; k < 4; k++) v |= (uint32_t)p[k] << (8 * k);
        s += v;
    }
    return s;
}

EXPORT("mSumU32Off2") uint32_t m_sum_u32_off2(void) {
    uint32_t s = 0;
    for (uint32_t i = 0; i < NW; i++) {
        uint32_t v;
        __builtin_memcpy(&v, bytes + 2 + 4 * i, 4);
        s += v;
    }
    return s;
}

EXPORT("mSumU64Off3") uint64_t m_sum_u64_off3(void) {
    uint64_t s = 0;
    for (uint32_t i = 0; i < NW / 2; i++) {
        uint64_t v;
        __builtin_memcpy(&v, bytes + 3 + 8 * i, 8);
        s += v;
    }
    return s;
}

EXPORT("mSumPacked") uint32_t m_sum_packed(void) {
    uint32_t s = 0;
    for (uint32_t i = 0; i < NH; i++)
        s += hdrs[i].kind + hdrs[i].len + hdrs[i].id + hdrs[i].crc;
    return s;
}

EXPORT("refSumWords") uint32_t ref_sum_words(void) {
    uint32_t s = 0;
    for (uint32_t i = 0; i < NW; i++) s += wval(i);
    return s;
}

EXPORT("refSumDwords") uint64_t ref_sum_dwords(void) {
    uint64_t s = 0;
    for (uint32_t i = 0; i < NW / 2; i++) s += dval(i);
    return s;
}

EXPORT("refSumPoints") uint32_t ref_sum_points(void) {
    uint32_t s = 0;
    for (uint32_t i = 0; i < NP; i++) s += (wval(i) ^ wval(i + 100)) + i;
    return s;
}

EXPORT("refSumU32At") uint32_t ref_sum_u32_at(uint32_t off) {
    if (off > 16) return 0;
    uint32_t s = 0;
    for (uint32_t i = 0; i < NW; i++) s += pat32(off + 4 * i);
    return s;
}

EXPORT("refSumU64Off3") uint64_t ref_sum_u64_off3(void) {
    uint64_t s = 0;
    for (uint32_t i = 0; i < NW / 2; i++) s += pat64(3 + 8 * i);
    return s;
}

EXPORT("refSumPacked") uint32_t ref_sum_packed(void) {
    uint32_t s = 0;
    for (uint32_t i = 0; i < NH; i++)
        s += i + wval(i + 200) + (uint16_t)(i * 7) + wval(i + 300);
    return s;
}
