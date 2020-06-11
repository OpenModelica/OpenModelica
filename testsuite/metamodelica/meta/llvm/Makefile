ROOT_DIR = $(realpath ..)
TEST = ../../../rtest -v +d=jit_eval_func

# test that currently fail. Move up when fixed.
# Run make testfailing
FAILINGTESTFILES = $(ROOT_DIR)/MatchCase8.mos

# Tests for LLVM
TESTFILES = \
AlgorithmsLLVM.mos \
BuiltinArrayLLVM.mos \
BuiltinIntegerLLVM.mos\
BuiltinRealLLVM.mos\
BuiltinStringLLVM.mos\
ComplicatedInteractiveLLVM.mos\
ListInteractiveLLVM.mos \
TupleInteractiveLLVM.mos

TESTFILES_META = \
$(ROOT_DIR)/Uniontype7.mos \
$(ROOT_DIR)/Uniontype8.mos \
$(ROOT_DIR)/Uniontype9.mos \
$(ROOT_DIR)/Uniontype10.mos \
$(ROOT_DIR)/Uniontype11.mos \
$(ROOT_DIR)/Uniontype12.mos \
$(ROOT_DIR)/Uniontype14.mos \
$(ROOT_DIR)/Uniontype15.mos \
$(ROOT_DIR)/SwitchString.mos \
$(ROOT_DIR)/Recursive.mos \
$(ROOT_DIR)/BuiltinMisc.mos \
$(ROOT_DIR)/ThreadedReduction.mos \
$(ROOT_DIR)/PackageConst1.mos \
$(ROOT_DIR)/MatchElse1.mos \
$(ROOT_DIR)/MatchCase6.mos \
$(ROOT_DIR)/MatchCase7.mos \
$(ROOT_DIR)/MatchCase11.mos \
$(ROOT_DIR)/MatchCase12.mos \
$(ROOT_DIR)/MatchCase13.mos \


# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
*.mos \
Makefile \
PartialFn6.ext_f.c \
compilelog.txt

CLEAN = `ls | grep -w -v -f deps.tmp`

.PHONY : test clean getdeps failingtest

test:
	@echo test
	@echo Running a set of standard tests with LLVM
	@$(TEST) $(TESTFILES_META)
	@echo Running LLVM Specific tests...
	@echo OPENMODELICAHOME=" $(OPENMODELICAHOME) "
	@$(TEST) $(TESTFILES)

# Cleans all files that are not listed as dependencies
clean :
	@echo $(DEPENDENCIES) | sed 's/ /\\|/g' > deps.tmp
	@rm -f $(CLEAN)

# Run this if you want to list out the files (dependencies).
# do it after cleaning and updating the folder
# then you can get a list of file names (which must be dependencies
# since you got them from repository + your own new files)
# then add them to the DEPENDENCIES. You can find the
# list in deps.txt
getdeps:
	@echo $(DEPENDENCIES) | sed 's/ /\\|/g' > deps.tmp
	@echo $(CLEAN) | sed -r 's/deps.txt|deps.tmp//g' | sed 's/ / \\\n/g' > deps.txt
	@echo Dependency list saved in deps.txt.
	@echo Copy the list from deps.txt and add it to the Makefile @DEPENDENCIES


failingtest :
	@echo
	@echo Running failing tests...
	@echo
	@$(TEST) $(FAILINGTESTFILES)

failingtestLLVM :
	@echo
	@echo Running failing llvm tests...
	@echo
	@$(TEST) $(FAILINGTESTFILES_LLVM)
