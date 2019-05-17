# BuiltinReal.mos fails when using Cevalfunc.mo! the values are OK, the display is different!
TEST = ../../../rtest -v


ifeq ($(OMDEV),)
	PATH := ./:${PATH}
else
	# this DOES NOT WORK ON WINDOWS! PATH := ./;${PATH}
endif

TESTFILES = \
helloWorld.mos \
BouncingBall.mos

# test that currently fail. Move up when fixed.

# Run make testfailing
FAILINGTESTFILES= \

# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
*.mos \
*ref_res.mat \
Makefile

UNAME := $(shell uname)

CLEAN = `ls | grep -w -v -f deps.tmp`

.PHONY : test clean getdeps failingtest

test:
	@echo
	@echo Running tests...
	@echo
	@echo OPENMODELICAHOME=" $(OPENMODELICAHOME) "
	@$(TEST) $(TESTFILES)


# Cleans all files that are not listed as dependencies
clean:
	@echo $(DEPENDENCIES) | sed 's/ /\\|/g' > deps.tmp
	@rm -rf $(CLEAN)

# Run this if you want to list out the files (dependencies).
getdeps:
	@echo $(DEPENDENCIES) | sed 's/ /\\|/g' > deps.tmp
	@echo $(CLEAN) | sed -r 's/deps.txt|deps.tmp//g' | sed 's/ / \\\n/g' > deps.txt
	@echo Dependency list saved in deps.txt.
	@echo Copy the list from deps.txt and add it to the Makefile @DEPENDENCIES

failingtest:
	@echo
	@echo Running failing tests...
	@echo
	@$(TEST) $(FAILINGTESTFILES)
