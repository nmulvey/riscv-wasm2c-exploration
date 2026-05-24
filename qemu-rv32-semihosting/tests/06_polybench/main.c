#include <stdint.h>
#include <stdio.h>

/* rdcycle reader */
static inline uint64_t read_rdcycle(void) {
    uint32_t lo, hi, hi_again;
    do {
        asm volatile("csrrs %0, 0xc80, x0" : "=r" (hi));
        asm volatile("csrrs %0, 0xc00, x0" : "=r" (lo));
        asm volatile("csrrs %0, 0xc80, x0" : "=r" (hi_again));
    } while (hi != hi_again);
    return ((uint64_t)hi << 32) | lo;
}

/* Pre-allocated arrays */
#define N 32
double A[N][N], B[N][N], C[N][N], D[N][N];

/* 2mm kernel */
void kernel_2mm(void) {
    for (int i = 0; i < N; i++)
        for (int j = 0; j < N; j++)
            for (int k = 0; k < N; k++)
                C[i][j] += A[i][k] * B[k][j];
    
    for (int i = 0; i < N; i++)
        for (int j = 0; j < N; j++)
            for (int k = 0; k < N; k++)
                D[i][j] += C[i][k] * B[k][j];
}

int main(int argc, char* argv[]) {
    (void)argc;
    (void)argv;
    
    printf("PolyBench 2mm starting\n");
    
    uint64_t start = read_rdcycle();
    kernel_2mm();
    uint64_t end = read_rdcycle();
    
    uint64_t elapsed = end - start;
    printf("Cycles: %llu\n", (unsigned long long)elapsed);
    
    return 0;
}
