GIT_COMMIT := $(shell cat version)
CC            = clang
# both can be emptied on the command line, e.g. for glibc targets without static PIE (make STATIC_PIE=)
STATIC_PIE    = -static-pie
MIMALLOC      = -lmimalloc
CFLAGS        = -std=gnu99 -Os -D_FILE_OFFSET_BITS=64 -DGIT_COMMIT=\"$(GIT_COMMIT)\" -T data_sections.ld -ffunction-sections -fdata-sections -Wl,--gc-sections -static -Wall -Werror $(STATIC_PIE)
LIBS          = -lsquashfuse -lsquashfuse_ll -lzstd -lz -lfuse3 $(MIMALLOC)

all: runtime

runtime: runtime.c
	$(CC) -I/usr/local/include/squashfuse -I/usr/include/fuse3 $(CFLAGS) $^ $(LIBS) -o $@

clean:
	rm -f runtime
