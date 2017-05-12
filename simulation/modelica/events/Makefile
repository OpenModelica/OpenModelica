TEST = ../../../rtest -v

TESTFILES = \
bug1228.mos \
bug2667.mos \
bug2718.mos \
bug2752.mos \
bug2808.mos \
bug3092.mos \
bug3358.mos \
bug4419.mos \
ChatteringEventsTest1.mos \
ChatteringEventsTest2.mos \
CheckEvents.mos \
EventDelay.mos \
EventIteration.mos \
EventLoop.mos \
EventTests.mos  \
EventTests2.mos \
EventTests3.mos \
IntegerZeroCrossings.mos \
MathEventFuncs1.mos \
MathEventFuncs2.mos \
Reinit.mos \
sample1.mos \
sample2.mos \
ServerWithQueue.mos \
TestNoEventsFlags.mos \
whenInAlgorithm.mos \
whenTest1.mos \
whenTest2.mos \
ZeroCrossing.mos \

# test that currently fail. Move up when fixed. 
# Run make testfailing
FAILINGTESTFILES=  \
ChatteringFunctionTest1.mos \
ChatteringFunctionTest2.mos \
ChatteringNoEventsTest1.mos \
ChatteringNoEventsTest2.mos \
ZeroCrossingAlg.mos \


# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
*.mos \
Makefile \
EventTests.mat


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
