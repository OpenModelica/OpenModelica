# BuiltinReal.mos fails when using Cevalfunc.mo! the values are OK, the display is different!
TEST = ../../rtest

TESTFILES = \
AddClassAnnotation1.mos \
AddComment.mos \
AddComponent.mos \
AddComponent2.mos \
AddDeleteComponent.mos \
ChangeSourceFile.mos \
LargeFileChange.mos \
ListFile.mos \
MoveComment.mos \
MoveComponent.mos \
MoveConnection.mos \
removeComponentModifiers.mos \
Tables.mos \
TestDiffListAPI.mos \
ticket3619.mos \
ticket3642.mos \
Ticket4110.mos \
ticket4153.mos \
ticket4368.mos \
ticket5360.mos \
UTF8.mos

# test that currently fail. Move up when fixed.
# Run make testfailing
FAILINGTESTFILES= \


# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
*.mos \
Makefile

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
