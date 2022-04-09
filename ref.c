#include <stdio.h>
#include <stdint.h>
#include <byteswap.h>

void encrypt (uint32_t v[2], const uint32_t k[4]) {
    uint32_t v0=v[0], v1=v[1], sum=0, i;           /* set up */
    uint32_t delta=0x9E3779B9;                     /* a key schedule constant */
    uint32_t k0=k[0], k1=k[1], k2=k[2], k3=k[3];   /* cache key */
    for (i=0; i<32; i++) {                         /* basic cycle start */
        sum += delta;
        v0 += ((v1<<4) + k0) ^ (v1 + sum) ^ ((v1>>5) + k1);
        v1 += ((v0<<4) + k2) ^ (v0 + sum) ^ ((v0>>5) + k3);
    }                                              /* end cycle */
    v[0]=v0; v[1]=v1;
}

void decrypt (uint32_t v[2], const uint32_t k[4]) {
    uint32_t v0=v[0], v1=v[1], sum=0xC6EF3720, i;  /* set up; sum is (delta << 5) & 0xFFFFFFFF */
    uint32_t delta=0x9E3779B9;                     /* a key schedule constant */
    uint32_t k0=k[0], k1=k[1], k2=k[2], k3=k[3];   /* cache key */
    for (i=0; i<32; i++) {                         /* basic cycle start */
//        printf("%2d %08x|%08x\n", i, v0, v1);
        v1 -= ((v0<<4) + k2) ^ (v0 + sum) ^ ((v0>>5) + k3);
        v0 -= ((v1<<4) + k0) ^ (v1 + sum) ^ ((v1>>5) + k1);
        sum -= delta;
    }                                              /* end cycle */
    v[0]=v0; v[1]=v1;
}

void print32(uint32_t x){
    printf("%x\n", __bswap_32(x));
}

int main() {
        //uint32_t v[2] = {0x12345678, 0x12345678};
        uint32_t v[2] = {0x12345678, 0x90abcdef};
        //uint32_t k[4] = {0x12345678, 0x12345678, 0x12345678, 0x12345678};
        //uint32_t k[4] = {0x12121212, 0x34343434, 0x56565656, 0x78787878};
        //uint32_t k[4] = {0x11111111, 0x22222222, 0x33333333, 0x44444444};
        //uint32_t k[4] = {0x11111111, 0x11111111, 0x11111111, 0x11111111};
        uint32_t k[4] = {0x12345678, 0x90abcdef, 0xfedcba09, 0x87654321};
        printf("%08x%08x\n", v[0], v[1]);
        encrypt(v,k);
        //printf("%08x%08x\n", v[0], v[1]);
        //decrypt(v,k);
        printf("%08x%08x\n", v[0], v[1]);
        return 0;
}
