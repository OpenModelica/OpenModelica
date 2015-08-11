TEST = ../../../rtest -v

FAILINGTESTFILES = 

TESTFILES = \
SimpleResistor.mos \
ElectricalCircuit.mos \
MergingExample.mos \
BouncingBall.mos \
Modelica.Blocks.Examples.BooleanNetwork1.mos \
Modelica.Blocks.Examples.InverseModel.mos \
Modelica.Electrical.Analog.Examples.SwitchWithArc.mos \
Modelica.Electrical.Spice3.Examples.Graetz.mos \
Modelica.Electrical.Analog.Examples.OvervoltageProtection.mos \
Modelica.Electrical.Spice3.Examples.CoupledInductors.mos \
Modelica.Mechanics.MultiBody.Examples.Elementary.ThreeSprings.mos \
Modelica.Electrical.Analog.Examples.CompareTransformers.mos \
Modelica.Mechanics.Rotational.Examples.HeatLosses.mos \
Modelica.Electrical.Machines.Examples.SynchronousInductionMachines.SMEE_LoadDump.mos \
Modelica.Fluid.Examples.BranchingDynamicPipes.mos \
Modelica.Electrical.Analog.Examples.CauerLowPassSC.mos \
#Modelica.Fluid.Examples.BranchingDynamicPipes_tds.mos
#Modelica.Electrical.Spice3.Examples.CoupledInductors_cpp.mos

# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
*.mos \
*_prof.json \
Makefile \
ReferenceFiles \
ReferenceGraphs \
Profiling \
BenchmarkSuite \
*_ext.graphml \
PN_Converter \
cleanHpcOmTestsuite.py

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
