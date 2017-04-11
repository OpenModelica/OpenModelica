TEST = ../../../rtest -v

TESTFILES = \
cse1.mos \
cse2.mos \
cse2_comSubExp.mos \
cse3.mos \
cseFunctionCall1.mos \
cseFunctionCall2.mos \
cseFunctionCall3.mos \
cseFunctionCall4.mos \
cseFunctionCall4b.mos \
cseFunctionCall4c.mos \
cseFunctionCall4d.mos \
cseFunctionCall5.mos \
cseFunctionCall6.mos \
cseFunctionCall7.mos \
cseFunctionCall8.mos \
cseTestCall1.mos \
cseTestCall2.mos \
cseTestCall3.mos \
cseTestCall4.mos \
cseTestCall5.mos \
cseTestCall6.mos \
cseTestCall7.mos \
comSubExp1.mos \
ThermoSysPro.Examples.SimpleExamples.TestCentrifugalPump1.mos \
wrapFunctionCalls1.mos \
wrapFunctionCalls2.mos \
wrapFunctionCalls3.mos \
wrapFunctionCalls4.mos \
wrapFunctionCalls5.mos \
wrapFunctionCalls6.mos \
wrapFunctionCalls7.mos \
wrapFunctionCalls8.mos \
wrapFunctionCalls9.mos \
wrapFunctionCalls10.mos \
wrapFunctionCalls11.mos \
wrapFunctionCalls12.mos \
wrapFunctionCalls13.mos \
wrapFunctionCalls14.mos \

# test that currently fail. Move up when fixed. 
# Run make testfailing
FAILINGTESTFILES=  \



# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
*.mos \
Makefile \
ReferenceFiles \
cleanHpcOmTestsuite.py



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
