GIT_COMMIT := $(shell cat version)
UNAME_S := $(shell uname -s)

CFLAGS_COMMON = -std=gnu99 -Os -D_FILE_OFFSET_BITS=64 -DGIT_COMMIT=\"$(GIT_COMMIT)\" -T data_sections.ld -ffunction-sections -fdata-sections -Wl,--gc-sections -static -Wall -Werror

ifeq ($(UNAME_S),FreeBSD)
# Ports install below /usr/local, which the base compiler does not search by
# default. squashfuse pulls in the full set of compressors on FreeBSD.
#
# The link needs GNU ld from devel/binutils: lld rejects the INSERT AFTER
# .interp in data_sections.ld ("unable to insert .appimage after .interp")
# because a non-PIE static binary has no .interp section. -static-pie, which
# would give it one, is not usable here either, so ld.bfd it is.
CC            = cc
CFLAGS        = $(CFLAGS_COMMON) -B/usr/local/bin -fuse-ld=bfd
INCLUDES      = -I/usr/local/include -I/usr/local/include/squashfuse -I/usr/local/include/fuse3
LIBS          = -L/usr/local/lib -lsquashfuse -lsquashfuse_ll -lzstd -llzma -lz -llz4 -llzo2 -lfuse3 -lmimalloc -lmd -lpthread
else
CC            = clang
CFLAGS        = $(CFLAGS_COMMON) -static-pie
INCLUDES      = -I/usr/local/include/squashfuse -I/usr/include/fuse3
LIBS          = -lsquashfuse -lsquashfuse_ll -lzstd -lz -lfuse3 -lmimalloc
endif

all: runtime

runtime: runtime.c
	$(CC) $(INCLUDES) $(CFLAGS) $^ $(LIBS) -o $@

clean:
	rm -f runtime
