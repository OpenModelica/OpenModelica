TEST = ../../../../rtest -v

TESTFILES = \
BooleanNetwork1.mos \
BouncingBall.mos \
HelloFMIWorld.mos \
HelloFMIWorldEvent.mos \
IntegerNetwork1.mos \
testAssert.mos \
testChangeParam.mos \
testBug2764.mos \
testBug3034.mos \
testBug3049.mos \
testBug3763.mos \
testBug3846.mos \
testDiscreteStructe.mos \
testInitialEquationsFMI.mos \
TestSourceCodeFMU.mos \
ZeroStates.mos \
EnumerationTest.mos \
Modelica.Blocks.Sources.BooleanPulse.mos \
Modelica.Electrical.Analog.Examples.ChuaCircuit.mos \
Modelica_Mechanics_MultiBody_Examples_Elementary_Pendulum.mos \
FMIExercise.mos \
testDisableDep.mos \

# test that currently fail. Move up when fixed.
# Run make testfailing
FAILINGTESTFILES= \
Modelica_Mechanics_MultiBody_Examples_Elementary_DoublePendulum.mos \
testExperimentalFMU.mos

# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
*.mos \
Makefile \



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
