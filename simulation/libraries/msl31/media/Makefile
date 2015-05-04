TEST = ../../../../rtest -v

TESTFILES = \
Modelica.Media.Examples.MoistAir.mos \
Modelica.Media.Examples.IdealGasH2O.mos \
Modelica.Media.Examples.TestOnly.IdealGasN2.mos \
Modelica.Media.Examples.Tests.MediaTestModels.LinearFluid.LinearColdWater.mos \
Modelica.Media.Examples.TwoPhaseWater.TestTwoPhaseStates.mos \
Modelica.Media.Incompressible.Examples.TestGlycol.mos \
Modelica.Media.Examples.TestOnly.FlueGas.mos \
Modelica.Media.Examples.TestOnly.IdealGasN2Mix.mos \
Modelica.Media.Examples.Tests.MediaTestModels.Air.DryAirNasa.mos \
Modelica.Media.Examples.Tests.MediaTestModels.Air.MoistAir.mos \
Modelica.Media.Examples.Tests.MediaTestModels.Air.SimpleAir.mos \
Modelica.Media.Examples.Tests.MediaTestModels.IdealGases.Air.mos \
Modelica.Media.Examples.Tests.MediaTestModels.IdealGases.Nitrogen.mos \
Modelica.Media.Examples.Tests.MediaTestModels.IdealGases.SimpleNaturalGas.mos \
Modelica.Media.Examples.Tests.MediaTestModels.IdealGases.SimpleNaturalGasFixedComposition.mos \
Modelica.Media.Examples.Tests.MediaTestModels.Incompressible.Essotherm650.mos \
Modelica.Media.Examples.Tests.MediaTestModels.Incompressible.Glycol47.mos \
Modelica.Media.Examples.Tests.MediaTestModels.Water.IdealSteam.mos \
Modelica.Media.Examples.Tests.MediaTestModels.Water.WaterIF97OnePhase_ph.mos \
Modelica.Media.Examples.Tests.MediaTestModels.Water.WaterIF97_pT.mos \
Modelica.Media.Examples.Tests.MediaTestModels.Water.WaterIF97_ph.mos \
Modelica.Media.Examples.TwoPhaseWater.ExtendedProperties.mos \
Modelica.Media.Examples.WaterIF97.mos \
Modelica.Media.Examples.MixtureGases.mos \
Modelica.Media.Examples.TestOnly.MixIdealGasAir.mos 

# test that currently fail. Move up when fixed. 
# Run make testfailing
FAILINGTESTFILES=  \
Modelica.Media.Examples.Tests.MediaTestModels.LinearFluid.LinearWater_pT.mos \
Examples.SimpleLiquidWater.mos 

# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
*.mos \
Makefile \
simulate


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
