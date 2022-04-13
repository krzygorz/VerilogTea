#include <stdio.h>
#include <stdint.h>
#include <endian.h>
#include <string.h>

/*
 * A reference implementation of TEA, useful for debugging the verilog version.
 *
 * The encrypt and decrypt functions are adaptations of the reference
 * implementation. The adapted code was taken from Wikipedia:
 * https://en.wikipedia.org/wiki/Tiny_Encryption_Algorithm#Reference_code.
 *
 * See also the Linux implementation of TEA:
 * https://github.com/torvalds/linux/blob/4d2fa8b44b891f0da5ceda3e5a1402ccf0ab6f26/crypto/tea.c
 *
 * There are some small differences from the code in the TEA paper:
 * - long and unsigned long was replaced by uint32_t, to make the code more
 *   portable.
 * - minor stylistic changes, like replacing the while loop with a for loop
 *
 * IMPORTANT: The algorithm operates on arrays of 32-bit *integers*. If we want
 * to operate on a sequence of bytes, we have to define how to pack them into
 * 32-bit uints. The TEA paper does not specify how to do this.
 *
 * The Linux implementation interprets each 4 bytes as little-endian integers,
 * using `le32_to_cpu` which is a no-op on little-endian architectures. Output
 * data is also in little-endian form.
 *
 * This implementation uses Linux test vectors so it behaves in the same way.
 * For simplicity, this C reference requires a little-endian system. It was
 * tested on x86_64 linux.
 */

void print_bytes(void *ptr, int size) {
    unsigned char *p = ptr;
    int i;
    for (i=0; i<size; i++) {
        printf("%02hhx", p[i]);
    }
    printf("\n");
}

void encrypt (uint32_t v[2], const uint32_t k[4]) {
    uint32_t v0=v[0], v1=v[1], sum=0, i;           /* set up */
    uint32_t delta=0x9E3779B9;                     /* a key schedule constant */
    uint32_t k0=k[0], k1=k[1], k2=k[2], k3=k[3];   /* cache key */
    for (i=0; i<32; i++) {                         /* basic cycle start */
        // printf("%2d %08x%08x\n", i, htobe32(v0), htobe32(v1));
        sum += delta;
        v0 += ((v1<<4) + k0) ^ (v1 + sum) ^ ((v1>>5) + k1);
        v1 += ((v0<<4) + k2) ^ (v0 + sum) ^ ((v0>>5) + k3);
    }                                              /* end cycle */
    // printf("%2d %08x%08x\n", i, htobe32(v0), htobe32(v1));
    v[0]=v0; v[1]=v1;
}

void decrypt (uint32_t v[2], const uint32_t k[4]) {
    uint32_t v0=v[0], v1=v[1], sum=0xC6EF3720, i;  /* set up; sum is (delta << 5) & 0xFFFFFFFF */
    uint32_t delta=0x9E3779B9;                     /* a key schedule constant */
    uint32_t k0=k[0], k1=k[1], k2=k[2], k3=k[3];   /* cache key */
    for (i=0; i<32; i++) {                         /* basic cycle start */
        v1 -= ((v0<<4) + k2) ^ (v0 + sum) ^ ((v0>>5) + k3);
        v0 -= ((v1<<4) + k0) ^ (v1 + sum) ^ ((v1>>5) + k1);
        sum -= delta;
    }                                              /* end cycle */
    v[0]=v0; v[1]=v1;
}

void test(int n, char* ptext, char* ctext, char* key) {
    uint32_t v[2];
    uint32_t k[4];
    memcpy(v, ptext, 8);
    memcpy(k, key, 16);
    encrypt(v,k);
    if (memcmp(v,ctext,8)) {
        printf("Test %d wrong ciphertext ", n);
        print_bytes(v, 8);
    }
    decrypt(v,k);
    if (memcmp(v,ptext,8)) {
        printf("Test %d wrong plaintext ", n);
        print_bytes(v, 8);
    }
}

int main() {
    test(0, "\0\0\0\0\0\0\0\0", "\x0a\x3a\xea\x41\x40\xa9\xba\x94",
            "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0");
    test(1, "\x74\x65\x73\x74\x20\x6d\x65\x2e", "\x77\x5d\x2a\x6a\xf6\xce\x92\x09", 
            "\x2b\x02\x05\x68\x06\x14\x49\x76"
            "\x77\x5d\x0e\x26\x6c\x28\x78\x43");
    char* k2 = "\x09\x65\x43\x11\x66\x44\x39\x25"
                "\x51\x3a\x16\x10\x0a\x08\x12\x6e";
    test(2, "\x6c\x6f\x6e\x67\x65\x72\x5f\x74", "\xbe\x7a\xbb\x81\x95\x2d\x1f\x1e", k2);
    test(3, "\x65\x73\x74\x5f\x76\x65\x63\x74", "\xdd\x89\xa1\x25\x04\x21\xdf\x95", k2);
    return 0;
}
