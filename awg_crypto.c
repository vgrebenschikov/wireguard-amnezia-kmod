/* SPDX-License-Identifier: MIT */
#include <sys/param.h>
#include <sys/endian.h>
#include <sys/systm.h>

#include "awg_crypto.h"

#define ROTL32(v, n) (((v) << (n)) | ((v) >> (32 - (n))))
#define QR(a, b, c, d) do { \
	(a) += (b); (d) ^= (a); (d) = ROTL32((d), 16); \
	(c) += (d); (b) ^= (c); (b) = ROTL32((b), 12); \
	(a) += (b); (d) ^= (a); (d) = ROTL32((d), 8);  \
	(c) += (d); (b) ^= (c); (b) = ROTL32((b), 7);  \
} while (0)

static void
awg_chacha20_block(uint32_t out[16], const uint32_t in[16])
{
	uint32_t x[16];

	memcpy(x, in, sizeof(x));
	for (int i = 0; i < 10; i++) {
		QR(x[0], x[4], x[8], x[12]);
		QR(x[1], x[5], x[9], x[13]);
		QR(x[2], x[6], x[10], x[14]);
		QR(x[3], x[7], x[11], x[15]);
		QR(x[0], x[5], x[10], x[15]);
		QR(x[1], x[6], x[11], x[12]);
		QR(x[2], x[7], x[8], x[13]);
		QR(x[3], x[4], x[9], x[14]);
	}
	for (int i = 0; i < 16; i++)
		out[i] = htole32(x[i] + in[i]);
	explicit_bzero(x, sizeof(x));
}

void
awg_chacha20_ietf_xor(uint8_t *data, size_t len, const uint8_t nonce[12],
    const uint8_t key[32])
{
	uint32_t state[16] = {
		0x61707865, 0x3320646e, 0x79622d32, 0x6b206574
	};
	uint32_t stream[16];

	for (int i = 0; i < 8; i++)
		state[4 + i] = le32dec(key + i * 4);
	state[12] = 0;
	state[13] = le32dec(nonce);
	state[14] = le32dec(nonce + 4);
	state[15] = le32dec(nonce + 8);

	while (len != 0) {
		size_t block_len = MIN(len, sizeof(stream));
		awg_chacha20_block(stream, state);
		for (size_t i = 0; i < block_len; i++)
			data[i] ^= ((uint8_t *)stream)[i];
		data += block_len;
		len -= block_len;
		state[12]++;
	}
	explicit_bzero(stream, sizeof(stream));
	explicit_bzero(state, sizeof(state));
}

bool
awg_chacha20_selftest(void)
{
	static const uint8_t expected[64] = {
		0x76, 0xb8, 0xe0, 0xad, 0xa0, 0xf1, 0x3d, 0x90,
		0x40, 0x5d, 0x6a, 0xe5, 0x53, 0x86, 0xbd, 0x28,
		0xbd, 0xd2, 0x19, 0xb8, 0xa0, 0x8d, 0xed, 0x1a,
		0xa8, 0x36, 0xef, 0xcc, 0x8b, 0x77, 0x0d, 0xc7,
		0xda, 0x41, 0x59, 0x7c, 0x51, 0x57, 0x48, 0x8d,
		0x77, 0x24, 0xe0, 0x3f, 0xb8, 0xd8, 0x4a, 0x37,
		0x6a, 0x43, 0xb8, 0xf4, 0x15, 0x18, 0xa1, 0x1c,
		0xc3, 0x87, 0xb6, 0x69, 0xb2, 0xee, 0x65, 0x86,
	};
	uint8_t key[AWG_CHACHA20_KEY_SIZE] = { 0 };
	uint8_t nonce[AWG_CHACHA20_NONCE_SIZE] = { 0 };
	uint8_t stream[sizeof(expected)] = { 0 };
	bool ok;

	awg_chacha20_ietf_xor(stream, sizeof(stream), nonce, key);
	ok = timingsafe_bcmp(stream, expected, sizeof(expected)) == 0;
	explicit_bzero(stream, sizeof(stream));
	return (ok);
}
