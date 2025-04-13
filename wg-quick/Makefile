# Makefile for wg-quick installation

PREFIX?=	/usr/local
BINDIR?=	${PREFIX}/bin
RCDIR?=		${PREFIX}/etc/rc.d

SCRIPTS=	bin/wg-quick
RCFILES=	rc.d/wireguard

all:

install:
	${INSTALL} -d ${DESTDIR}${BINDIR}
	${INSTALL} -d ${DESTDIR}${RCDIR}
	${INSTALL} -m 555 ${SCRIPTS} ${DESTDIR}${BINDIR}
	${INSTALL} -m 555 ${RCFILES} ${DESTDIR}${RCDIR}

clean: 