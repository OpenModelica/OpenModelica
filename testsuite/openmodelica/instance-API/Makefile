TEST = ../../rtest -v

TESTFILES = \
GetModelInstanceAnnotation1.mos \
GetModelInstanceAnnotation2.mos \
GetModelInstanceAnnotation3.mos \
GetModelInstanceAttributes1.mos \
GetModelInstanceAttributes2.mos \
GetModelInstanceComment1.mos \
GetModelInstanceConditional1.mos \
GetModelInstanceConnection1.mos \
GetModelInstanceDerived1.mos \
GetModelInstanceDuplicate1.mos \
GetModelInstanceEnum1.mos \
GetModelInstanceEnum2.mos \
GetModelInstanceExp1.mos \
GetModelInstanceExtends1.mos \
GetModelInstanceExtends2.mos \
GetModelInstanceInnerOuter1.mos \
GetModelInstanceInnerOuter2.mos \
GetModelInstanceMod1.mos \
GetModelInstanceMod2.mos \
GetModelInstanceReplaceable1.mos \
GetModelInstanceStateMachine1.mos \


# test that currently fail. Move up when fixed.
# Run make testfailing
FAILINGTESTFILES=

# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
*.mos \
Makefile


CLEAN = `ls | grep -w -v -f deps.tmp`

.PHONY : test clean getdeps failingtest

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
