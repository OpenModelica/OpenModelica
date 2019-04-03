TEST = ../../../rtest -v

TESTFILES = \
inlineArray1.mos \
inlineArray2.mos \
inlineArray3.mos \
inlineArrayRecord.mos \
inlineFunction1.mos \
inlineFunction2.mos \
inlineFunction3.mos \
inlineFunction4.mos \
inlineFunction5.mos \
inlineFunction6.mos \
inlineFunction7.mos \
inlineFunction8.mos \
inlineFunction9.mos \
inlineFunction10.mos \
inlineFunction11.mos \
forceComplexEq.mos \
forceComplexEq2.mos \
forceComplexEq3.mos \
forceComplexEq4.mos \
testBug3687.mos \
testBug3997.mos \
testComplexMath.mos \
testBug4808.mos \
testBug4841.mos \


# test that currently fail. Move up when fixed.
# Run make failingtest
FAILINGTESTFILES = \

# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
*.mos \
Makefile \

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

failingtest:
	@echo
	@echo Running failing tests...
	@echo
	@$(TEST) $(FAILINGTESTFILES)
