#
# Makefile for modeq/runtime
#
# David Kågedal <x97davka@ida.liu.se>
#
# $Id$
#

RMLINCLUDE = /home/pelab/pub/pkg/rml/current/sol2-sparc/include/plain

SHELL	= /bin/sh
CC	= cc
CFLAGS	= -I$(RMLINCLUDE)

SRC	= rtopts.c

OBJ     = $(SRC:.c=.o)

all: $(OBJ)

clean:
	$(RM) $(OBJ)
