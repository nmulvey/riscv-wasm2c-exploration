#ifndef SETJMP_H
#define SETJMP_H
typedef int jmp_buf[64];
#define setjmp(x) 0
#define longjmp(x,y)
#endif
