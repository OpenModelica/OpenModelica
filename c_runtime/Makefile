CC = gcc
AR = ar -ru
CFLAGS = -Wall -ansi -pedantic



OBJS = boolean_array.o index_spec.o integer_array.o memory_pool.o \
	real_array.o string_array.o read_write.o

all : libc_runtime.a


libc_runtime.a : $(OBJS)
	$(AR) $@ $(OBJS)

clean :
	rm -f libc_runtime.a
	rm -f $(OBJS)
