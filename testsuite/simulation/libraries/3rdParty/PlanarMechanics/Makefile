TEST = ../../../../rtest -v

TESTFILES = \
PlanarMechanicsForTesting.Examples.FreeBody.mos \
PlanarMechanicsForTesting.Examples.Pendulum.mos \
PlanarMechanicsForTesting.Examples.DoublePendulum.mos \
PlanarMechanicsForTesting.Examples.CounterSpin.mos \
PlanarMechanicsForTesting.Examples.CraneCrab.mos \
PlanarMechanicsForTesting.Examples.ControlledCraneCrab.mos \
PlanarMechanicsForTesting.Examples.InvertedCraneCrab.mos \
PlanarMechanicsForTesting.Examples.KinematicLoop.mos \
PlanarMechanicsForTesting.Examples.KinematicLoop_DynamicStateSelection.mos \
PlanarMechanicsForTesting.Examples.PistonEngine.mos \
PlanarMechanicsForTesting.Examples.PistonEngine_DynamicStateSelection.mos \
PlanarMechanicsForTesting.Examples.TestDryFrictionWheel.mos \
PlanarMechanicsForTesting.Examples.TestSlipBasedWheel.mos \
PlanarMechanicsForTesting.Examples.TestIdealWheel.mos \
PlanarMechanicsForTesting.Examples.SingleTrackWithEngine.mos \
PlanarMechanicsForTesting.Examples.SimpleCarWithDifferentialGear.mos \
PlanarMechanicsForTesting.Examples.WheelBasedCranCrab.mos 

# test that currently fail. Move up when fixed. 
# Run make testfailing
FAILINGTESTFILES=  \

# PlanarMechanicsForTesting.Examples.KinematicLoop.mos failed because of wrong initial values

# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
 *.mo \
 *.mos \
 Makefile \
 ReferenceFiles
	

CLEAN = `ls | grep -w -v -f deps.tmp`

.PHONY : test clean getdeps

test :
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
	@$(TEST) $(FAILINGTESTFILES) \
