CC = gcc
CFLAGS = -fPIC -Wall -Wextra -O2 -g
LDFLAGS = -shared
RM = rm -f
TARGET_LIB = libFFITestLib.so
TARGET_DIR = linux64

OBJS = FFITestLib.o

.PHONY: all
all: ${TARGET_LIB}

$(TARGET_LIB): $(OBJS)
	$(CC) ${LDFLAGS} -o $@ $<
	mkdir -p ../../Library/$(TARGET_DIR)
	cp $@ ../../Library/$(TARGET_DIR)/$@

%.o: ../../C-Sources/%.c
	$(CC) $(CFLAGS) -c -o $@ $<

.PHONY: clean
clean:
	-${RM} ${TARGET_LIB} ${OBJS} $(SRCS:.c=.d)
