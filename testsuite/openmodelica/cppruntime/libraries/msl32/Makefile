TEST = ../../../../rtest -v

TESTFILES = \
Modelica.Blocks.Examples.Filter.mos \
Modelica.Blocks.Examples.BooleanNetwork1.mos \
Modelica.Electrical.Analog.Examples.CauerLowPassSC.mos \
Modelica.Electrical.QuasiStationary.SinglePhase.Examples.ParallelResonance.mos \
Modelica.Electrical.Spice3.Examples.CoupledInductors.mos \
Modelica.Electrical.Analog.Examples.ShowSaturatingInductor.mos \
Modelica.Mechanics.MultiBody.Examples.Elementary.DoublePendulum.mos \
Modelica.Mechanics.MultiBody.Examples.Elementary.RollingWheelSetDriving.mos \
Modelica.Mechanics.MultiBody.Examples.Elementary.SpringWithMass.mos \
Modelica.Mechanics.Rotational.Examples.Backlash.mos \
Modelica.Mechanics.Rotational.Examples.RollingWheel.mos \
Modelica.Mechanics.Translational.Examples.Accelerate.mos \
Modelica.Mechanics.Translational.Examples.InitialConditions.mos \
Modelica.Media.Examples.IdealGasH2O.mos \
Modelica.Media.Examples.TestOnly.IdealGasN2.mos \
Modelica.Media.Examples.Tests.MediaTestModels.Air.DryAirNasa.mos \
Modelica.Media.Examples.WaterIF97.mos \
Modelica.StateGraph.Examples.FirstExample.mos \
Modelica.Thermal.HeatTransfer.Examples.ControlledTemperature.mos \
Modelica.Thermal.HeatTransfer.Examples.TwoMasses.mos \
Modelica.Electrical.Digital.Examples.Counter.mos \
Modelica.Utilities.Examples.readRealParameterModel.mos \


# tested features:
# readRealParameterModel: string handling, variable name string

# Run make failingtest
FAILINGTESTFILES=\
Modelica.Mechanics.MultiBody.Examples.Elementary.FreeBody.mos \


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

failingtest:
	@echo
	@echo Running failing tests...
	@echo
	@$(TEST) $(FAILINGTESTFILES)
