#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "tweetnacl.wasm.h"

/* #define MSG_LEN 64 */
/* #define ZERO_PAD 32 */
/* #define BOX_PAD 16 */

struct w2c_env {
    w2c_tweetnacl* instance;
    uint32_t heap_ptr;
};

// ----- WASM sandbox bump allocator -----

void wasm_tweetnacl_heap_init(struct w2c_env* env) {
    // Start allocating from the WASM heap base, aligned to 8 bytes
    env->heap_ptr = (env->instance->w2c_0x5F_heap_base + 7) & ~7;
}

uint32_t wasm_tweetnacl_heap_alloc(struct w2c_env* env, uint32_t size) {
    uint32_t ptr = env->heap_ptr;
    env->heap_ptr += (size + 7) & ~7; // Bump and align
    return ptr;
}

// ----- PRNG -----

static uint32_t prng_state = 12345;
static uint32_t prng_next(void) {
    prng_state = prng_state * 1103515245 + 12345;
    return (prng_state / 65536) % 32768;
}

void randombytes(unsigned char* x, unsigned long long xlen) {
    for (unsigned long long i = 0; i < xlen; i++) {
        x[i] = prng_next() & 0xFF;
    }
}

// ----- PRNG exposed to WASM -----

void w2c_env_randombytes(struct w2c_env* env, uint32_t buf_offset, uint64_t len) {
    if (buf_offset > env->instance->w2c_memory.size ||
        len > env->instance->w2c_memory.size - buf_offset) {
        return;
    }

    unsigned char* target_ptr = (unsigned char*)(env->instance->w2c_memory.data + buf_offset);
    randombytes(target_ptr, (unsigned long long)len);
}

// ----- Host <-> WASM memcpy helpers -----

// Safely copy data from Host to WASM memory
bool memcpy_to_wasm(w2c_tweetnacl* inst, uint32_t wasm_dst_offset, const void* host_src,
                    size_t len) {
    if (wasm_dst_offset > inst->w2c_memory.size || len > inst->w2c_memory.size - wasm_dst_offset) {
        return false; // Out of bounds
    }
    memcpy(inst->w2c_memory.data + wasm_dst_offset, host_src, len);
    return true;
}

// Safely copy data from WASM memory to Host
bool memcpy_from_wasm(void* host_dst, const w2c_tweetnacl* inst, uint32_t wasm_src_offset,
                      size_t len) {
    if (wasm_src_offset > inst->w2c_memory.size || len > inst->w2c_memory.size - wasm_src_offset) {
        return false; // Out of bounds
    }
    memcpy(host_dst, inst->w2c_memory.data + wasm_src_offset, len);
    return true;
}

// ----- Wrappers around wasm2c-exposed functions -----

// tweetnacl.h has a define for `crypto_box_keypair`, internally calls
// `crypto_box_curve25519xsalsa20poly1305_tweet_keypair`:
uint32_t crypto_box_keypair_wrapped(struct w2c_env* env, unsigned char* pk, unsigned char* sk) {
    // Save current allocator state
    uint32_t saved_heap_ptr = env->heap_ptr;

    uint32_t wasm_pk = wasm_tweetnacl_heap_alloc(env, 32);
    uint32_t wasm_sk = wasm_tweetnacl_heap_alloc(env, 32);

    uint32_t result = w2c_tweetnacl_crypto_box_curve25519xsalsa20poly1305_tweet_keypair(
        env->instance, wasm_pk, wasm_sk);

    if (result == 0) {
        memcpy_from_wasm(pk, env->instance, wasm_pk, 32);
        memcpy_from_wasm(sk, env->instance, wasm_sk, 32);
    }

    // Restore allocator state (frees the memory)
    //
    // TODO: this is crude.
    env->heap_ptr = saved_heap_ptr;

    return result;
}

int main(int argc, char* argv[]) {
    (void)argc;
    (void)argv;

    printf("Testing TweetNaCl crypto_box\n\n");

    wasm_rt_init();

    w2c_tweetnacl instance;
    struct w2c_env env;
    env.instance = &instance;

    // Pass the environment to resolve the randombytes import:
    wasm2c_tweetnacl_instantiate(&instance, &env);

    // Initialize the allocator state:
    wasm_tweetnacl_heap_init(&env);

    unsigned char pk[32], sk[32];
    unsigned char pk2[32], sk2[32];

    printf("Generating keypairs...\n");

    if (crypto_box_keypair_wrapped(&env, pk, sk) != 0) {
        fprintf(stderr, "Error: Failed to generate first keypair.\n");
        return 1;
    }

    if (crypto_box_keypair_wrapped(&env, pk2, sk2) != 0) {
        fprintf(stderr, "Error: Failed to generate second keypair.\n");
        return 1;
    }

    printf("Keypairs generated successfully.\n");

    /* /\* NaCl requires 32-byte zero padding before plaintext *\/ */
    /* unsigned char msg[ZERO_PAD + MSG_LEN]; */
    /* unsigned char cipher[ZERO_PAD + MSG_LEN]; */
    /* unsigned char decrypted[ZERO_PAD + MSG_LEN]; */
    /* unsigned char nonce[24]; */

    /* printf("Preparing message and nonce...\n"); */
    /* memset(msg, 0, ZERO_PAD); */
    /* memset(msg + ZERO_PAD, 0x42, MSG_LEN); */
    /* memset(nonce, 0x00, 24); */

    /* printf("Encrypting...\n"); */
    /* int ret = crypto_box(cipher, msg, ZERO_PAD + MSG_LEN, nonce, pk2, sk); */
    /* if (ret != 0) { */
    /*     printf("FAIL: crypto_box encryption failed\n"); */
    /*     return 1; */
    /* } */
    /* printf("PASS: crypto_box encryption succeeded\n"); */

    /* printf("Decrypting...\n"); */
    /* ret = crypto_box_open(decrypted, cipher, ZERO_PAD + MSG_LEN, nonce, pk, sk2); */
    /* if (ret != 0) { */
    /*     printf("FAIL: crypto_box decryption failed\n"); */
    /*     return 1; */
    /* } */
    /* printf("PASS: crypto_box decryption succeeded\n"); */

    /* if (memcmp(decrypted + ZERO_PAD, msg + ZERO_PAD, MSG_LEN) != 0) { */
    /*     printf("FAIL: Decrypted message doesn't match original\n"); */
    /*     return 1; */
    /* } */
    /* printf("PASS: Decrypted message matches original\n\n"); */
    /* printf("All crypto_box tests passed!\n"); */

    return 0;
}
