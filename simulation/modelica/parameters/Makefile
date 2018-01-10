TEST = ../../../rtest -v

TESTFILES = \
fixedString.mos \
parameterTest.mos \
parameterTest2.mos \
parameterTest3.mos \
parameterTest4.mos \
parameterTest5.mos \
parameterTest6.mos \
parameterTest7.mos \
parameterTest8.mos \
parameterTest9.mos \
parameterTest10.mos \
parameterTest11.mos \
parameterTest12.mos \
parameterTest13.mos \
parameterTest14.mos \
parameterTest15.mos \
parameterTest16.mos \
parameterTest17.mos \
Engine1a_output.mos \
revoluteConstraint.mos \
hideResult.mos \

# test that currently fail. Move up when fixed. 
# Run make testfailing
FAILINGTESTFILES= \

# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
*.mos \
Makefile 


CLEAN = `ls | grep -w -v -f deps.tmp`

.PHONY : test clean getdeps

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
