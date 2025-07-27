PACKAGE=	tests

# TESTSDIR=	${TESTSBASE}/sys/net
# BINDIR=		${TESTSDIR}

ATF_TESTS_SH+=	if_wg

# The netmap bridge application is used by if_wg tests.
#.PATH:	${SRCTOP}/tools/tools/netmap
.PATH:	/usr/src/tools/tools/netmap
PROGS+=		bridge
LIBADD.bridge+=	netmap

# The tests are written to be run in parallel, but doing so leads to random
# panics.  I think it's because the kernel's list of interfaces isn't properly
# locked.
TEST_METADATA+=	is_exclusive=true


MAN=

CFLAGS+=        -I${.CURDIR:H:H}

.include <bsd.test.mk>

test: all
	kyua test
