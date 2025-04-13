PROG=	wg
MAN=	wg.8

LDADD=	-lnv

.PATH: ../contrib/wireguard-tools
.PATH: ../contrib/wireguard-tools/man

SRCS+=	wg.c

SRCS+=	config.c
SRCS+=	encoding.c
SRCS+=	ipc.c
SRCS+=	terminal.c

SRCS+=	curve25519.c

# Subcommands
SRCS+=	show.c
SRCS+=	showconf.c
SRCS+=	set.c
SRCS+=	setconf.c
SRCS+=	genkey.c
SRCS+=	pubkey.c

# Base should pull RUNSTATEDIR from paths.h, _PATH_VARRUN
CFLAGS+=	-include paths.h
CFLAGS+=	-DRUNSTATEDIR="_PATH_VARRUN"

# Not going to change this one.
CWARNFLAGS.curve25519.c+=	-Wno-shadow

# sockaddr{,_in} alignment
CWARNFLAGS.config.c+=	-Wno-cast-align
CWARNFLAGS.ipc.c+=	-Wno-cast-align

BINDIR?=	/usr/local/bin
MANDIR?=	/usr/local/man

# Custom install target
install: all
	${INSTALL} -d ${DESTDIR}${MANDIR}/man8
	${INSTALL} -o root -g wheel -m 444 ${PROG}.8.gz ${DESTDIR}${MANDIR}/man8/
	${INSTALL} -s -o root -g wheel -m 555 ${PROG} ${DESTDIR}${BINDIR}/${PROG}

.include <bsd.prog.mk>
