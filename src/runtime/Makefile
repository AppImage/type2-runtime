GIT_COMMIT := $(shell cat version)
CC            = clang
CFLAGS        = -std=gnu99 -Os -D_FILE_OFFSET_BITS=64 -DGIT_COMMIT=\"$(GIT_COMMIT)\" -T data_sections.ld -ffunction-sections -fdata-sections -Wl,--gc-sections -static -Wall -Werror -static-pie
LIBS          = -lsquashfuse -lsquashfuse_ll -lzstd -lz -lfuse3 -lmimalloc

all: runtime

runtime: runtime.c
	$(CC) -I/usr/local/include/squashfuse -I/usr/include/fuse3 $(CFLAGS) $^ $(LIBS) -o $@

clean:
	rm -f runtime
