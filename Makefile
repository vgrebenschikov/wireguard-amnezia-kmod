
KMOD= if_wg

SRCS= if_wg.c wg_cookie.c wg_crypto.c wg_noise.c awg_crypto.c
SRCS+= opt_inet.h opt_inet6.h device_if.h bus_if.h

.include <bsd.kmod.mk>

CFLAGS+= -include compat.h
CFLAGS+= -DAWG2_CLIENT_COMPAT
