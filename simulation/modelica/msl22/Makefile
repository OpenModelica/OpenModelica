TEST = ../../../rtest -v

TESTFILES = \
avg.mos \
Backlash.mos \
blockssources.mos \
Circuit1.mos \
DCMotorBlocks.mos \
DCMotorDeadzone.mos \
DCMotorRotational.mos \
ElasticBearing.mos \
First.mos \
FuncCross.mos \
IdealGear.mos \
IdealGearBrake.mos \
InputOutput.mos \
InitTest.mos \
MatrixTest.mos \
NonLinsys.mos \
Shaft.mos \
simulation2.mos \
SineAccelerate.mos \
SineSpeed.mos \
SineTorque.mos \
SineTorque2inertias.mos \
SpringMass.mos \
StepTorque.mos \
Tank.mos \
Test3PhaseInit.mos \
Test3PhaseInitParam.mos \
Test3PhaseInitOver.mos \
Test3PhaseStart.mos \
TimeVaryingLinsys.mos \
TrapezoidTest.mos \
tupleTest.mos \
WeakAxis.mos

# test that currently fail. Move up when fixed. 
# Run make testfailing
FAILINGTESTFILES=\
BearingFrictionTest.mos \
LossyGear1.mos \
Gear.mos \
Gear2.mos \

# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
*.mos \
Makefile 

CLEAN = `ls | grep -w -v -f deps.tmp`

.PHONY : test failingtest clean getdeps

test :
	@echo
	@echo Running tests...
	@echo
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
