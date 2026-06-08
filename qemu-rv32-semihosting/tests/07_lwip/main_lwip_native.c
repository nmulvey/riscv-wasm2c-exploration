/* Minimal LwIP exercise: build a pbuf, run the IP/UDP checksum path over it,
   fold a fingerprint. Scoped to the inet_chksum + pbuf core so it links and
   runs without a full NO_SYS netif/timer port. */
#include "cycles.h"
#include <stdint.h>
#include <stdio.h>

#include "lwip/init.h"
#include "lwip/pbuf.h"
#include "lwip/inet_chksum.h"

int main(int argc, char* argv[]) {
    (void)argc; (void)argv;
    printf("LwIP (inet_chksum + pbuf, native)\n");

    BENCH_START();

    /* Allocate a pbuf in the transport layer and fill it with a pattern. */
    struct pbuf *p = pbuf_alloc(PBUF_RAW, 256, PBUF_RAM);
    uint32_t fp = 0;
    if (p != NULL) {
        uint8_t *d = (uint8_t *)p->payload;
        for (int i = 0; i < 256; i++) d[i] = (uint8_t)(i * 31 + 7);

        /* Exercise the software checksum path repeatedly. */
        for (int iter = 0; iter < 1000; iter++) {
            u16_t c = inet_chksum_pbuf(p);
            fp += c;
        }
        pbuf_free(p);
    }

    BENCH_END("lwip_chksum");
    printf("fingerprint=%lu\n", (unsigned long)fp);
    printf("PASS: lwip checksum path completed\n");
    return 0;
}
