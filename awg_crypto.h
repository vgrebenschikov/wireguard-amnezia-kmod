#ifndef _AWG_CRYPTO_H_
#define _AWG_CRYPTO_H_

#include <sys/types.h>

#define AWG_CHACHA20_KEY_SIZE 32
#define AWG_CHACHA20_NONCE_SIZE 12

void awg_chacha20_ietf_xor(uint8_t *, size_t,
    const uint8_t[AWG_CHACHA20_NONCE_SIZE],
    const uint8_t[AWG_CHACHA20_KEY_SIZE]);
bool awg_chacha20_selftest(void);

#endif
