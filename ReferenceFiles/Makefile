ALL_MAT := $(patsubst %.mat.xz,%.mat,$(wildcard */*.mat.xz))
.PHONY: all

all: $(ALL_MAT)
%.mat: %.mat.xz
	xz --keep --decompress --force $<
