#include "tweetnacl.h"
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define MSG_LEN 64
#define ZERO_PAD 32
#define BOX_PAD 16

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

int main(int argc, char* argv[]) {
    (void)argc;
    (void)argv;

    printf("Testing TweetNaCl crypto_box\n\n");

    unsigned char pk[32], sk[32];
    unsigned char pk2[32], sk2[32];

    printf("Generating keypairs...\n");
    crypto_box_keypair(pk, sk);
    crypto_box_keypair(pk2, sk2);

    /* NaCl requires 32-byte zero padding before plaintext */
    unsigned char msg[ZERO_PAD + MSG_LEN];
    unsigned char cipher[ZERO_PAD + MSG_LEN];
    unsigned char decrypted[ZERO_PAD + MSG_LEN];
    unsigned char nonce[24];

    printf("Preparing message and nonce...\n");
    memset(msg, 0, ZERO_PAD);
    memset(msg + ZERO_PAD, 0x42, MSG_LEN);
    memset(nonce, 0x00, 24);

    printf("Encrypting...\n");
    int ret = crypto_box(cipher, msg, ZERO_PAD + MSG_LEN, nonce, pk2, sk);
    if (ret != 0) {
        printf("FAIL: crypto_box encryption failed\n");
        return 1;
    }
    printf("PASS: crypto_box encryption succeeded\n");

    printf("Decrypting...\n");
    ret = crypto_box_open(decrypted, cipher, ZERO_PAD + MSG_LEN, nonce, pk, sk2);
    if (ret != 0) {
        printf("FAIL: crypto_box decryption failed\n");
        return 1;
    }
    printf("PASS: crypto_box decryption succeeded\n");

    if (memcmp(decrypted + ZERO_PAD, msg + ZERO_PAD, MSG_LEN) != 0) {
        printf("FAIL: Decrypted message doesn't match original\n");
        return 1;
    }
    printf("PASS: Decrypted message matches original\n\n");
    printf("All crypto_box tests passed!\n");
    return 0;
}
