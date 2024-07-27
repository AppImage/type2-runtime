CC            = gcc
CFLAGS        = -std=gnu99 -s -Os -D_FILE_OFFSET_BITS=64 -DGIT_COMMIT=\"${GIT_COMMIT}\" -T data_sections.ld -ffunction-sections -fdata-sections -Wl,--gc-sections -static -Wall -Werror
LIBS          = -lsquashfuse -lsquashfuse_ll -lzstd -lz

all: runtime-fuse3 runtime-fuse3

# Compile runtime
runtime-fuse3.o: runtime.c
	$(CC) -I/usr/local/include/squashfuse -I/usr/include/fuse -o runtime-fuse3.o -c $(CFLAGS) $^

runtime-fuse3: runtime-fuse3.o
	$(CC) $(CFLAGS) $^ $(LIBS) -lfuse -o runtime-fuse3

runtime-fuse3.o: runtime.c
	$(CC) -I/usr/local/include/squashfuse -I/usr/include/fuse3 -o runtime-fuse3.o -c $(CFLAGS) $^

runtime-fuse3: runtime-fuse3.o
	$(CC) $(CFLAGS) $^ $(LIBS) -lfuse3 -o runtime-fuse3

clean:
	rm -f *.o runtime-fuse3 runtime-fuse3
