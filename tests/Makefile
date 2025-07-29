PACKAGE=	tests

ATF_TESTS_SH+=	if_wg
ATF_TESTS_SH+=	if_awg

# The netmap bridge application is used by if_wg tests.
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
