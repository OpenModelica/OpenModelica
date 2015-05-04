TEST = ../../../../rtest -v

TESTFILES = \


# test that currently fail. Move up when fixed. 
# Run make testfailing
FAILINGTESTFILES= \
Modelica.Fluid.Examples.ControlledTankSystem.ControlledTanks.mos \
Modelica.Fluid.Examples.DrumBoiler.DrumBoiler.mos \
Modelica.Fluid.Examples.Explanatory.MeasuringTemperature.mos \
Modelica.Fluid.Examples.HeatingSystem.mos \
Modelica.Fluid.Examples.AST_BatchPlant.Test.OneTank.mos \
Modelica.Fluid.Examples.AST_BatchPlant.Test.TanksWithEmptyingPipe1.mos \
Modelica.Fluid.Examples.AST_BatchPlant.Test.TanksWithEmptyingPipe2.mos \
Modelica.Fluid.Examples.AST_BatchPlant.Test.TankWithEmptyingPipe1.mos \
Modelica.Fluid.Examples.AST_BatchPlant.Test.TankWithEmptyingPipe2.mos \
Modelica.Fluid.Examples.AST_BatchPlant.Test.TwoTanks.mos \
Modelica.Fluid.Examples.BranchingDynamicPipes.mos \
Modelica.Fluid.Examples.Explanatory.MomentumBalanceFittings.mos \
Modelica.Fluid.Examples.HeatExchanger.HeatExchangerSimulation.mos \
Modelica.Fluid.Examples.IncompressibleFluidNetwork.mos \
Modelica.Fluid.Examples.InverseParameterization.mos \
Modelica.Fluid.Examples.PumpingSystem.mos \
Modelica.Fluid.Examples.Tanks.EmptyTanks.mos \
Modelica.Fluid.Examples.Tanks.TanksWithOverflow.mos \
Modelica.Fluid.Examples.Tanks.ThreeTanks.mos \
Modelica.Fluid.Examples.TraceSubstances.RoomCO2.mos \
Modelica.Fluid.Examples.TraceSubstances.RoomCO2WithControls.mos 

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
