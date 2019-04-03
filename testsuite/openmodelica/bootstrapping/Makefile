# BuiltinReal.mos fails when using Cevalfunc.mo! the values are OK, the display is different!
TEST = ../../rtest

TESTFILES = \
DiffAlgorithm.mos \
DumpTest.mos \
ExpandableArrayTest.mos \
ExpressionTest.mos \
GraphTest.mos \
HashTableTest.mos \
JSONParser.mos \
PriorityQueue.mos \
SimplifyTest.mos \
System.mos \
UtilTest.mos \
VectorTest.mos

# test that currently fail. Move up when fixed.
# Run make testfailing
FAILINGTESTFILES= \
PVectorTest.mos


# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
*.mos \
Makefile \
BreakProcess.cpp \
LinkMain.makefile.in \
LinkMain.makefile.mingw \
SusanTestSmall.tpl \
main.c \
main_records.c \
main_separate.c \
refactor-mc-to-m.sh

# Remove executables on Linux (no extension)
# CLEAN = $(TESTFILES:.mos=) $(TESTFILES:.mos=_*) $(TESTFILES:.mos=.cpp) $(TESTFILES:.mos=.makefile) $(TESTFILES:.mos=.libs) $(TESTFILES:.mos=.log) output.log *.dll *.exe *.so

CLEAN = `ls | grep -w -v -f deps.tmp`

.PHONY : test

test:
	@echo
	@echo Running tests...
	@echo
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
