#ifndef LWIP_LWIPOPTS_H
#define LWIP_LWIPOPTS_H

#define NO_SYS                      1
#define SYS_LIGHTWEIGHT_PROT        0
#define LWIP_NETCONN                0
#define LWIP_SOCKET                 0

#define MEM_LIBC_MALLOC             0
#define MEMP_MEM_MALLOC             0
#define MEM_ALIGNMENT               4
#define MEM_SIZE                    (8 * 1024)

#define LWIP_IPV4                   1
#define LWIP_IPV6                   0
#define LWIP_TCP                    0
#define LWIP_UDP                    1
#define LWIP_RAW                    1
#define LWIP_ICMP                   1
#define LWIP_DHCP                   0
#define LWIP_ARP                    1
#define LWIP_ETHERNET               1

#define LWIP_STATS                  0
#define LWIP_DEBUG                  0

#define CHECKSUM_GEN_IP             1
#define CHECKSUM_CHECK_IP           1
#define CHECKSUM_GEN_UDP            1
#define CHECKSUM_CHECK_UDP          1

#define LWIP_NETIF_HOSTNAME         0
#define LWIP_NETCONN_FULLDUPLEX     0

#endif /* LWIP_LWIPOPTS_H */
