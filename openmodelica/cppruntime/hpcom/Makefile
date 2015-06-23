TEST = ../../../rtest -v

TESTFILES = \
BouncingBall_mcp_omp.mos \
Modelica.Electrical.Spice3.Examples.CoupledInductors_level.mos \
Modelica.Electrical.Analog.Examples.CauerLowPassSC_level_omp.mos \
Modelica.Electrical.Analog.Examples.CauerLowPassSC_levelfix_memory.mos \
Modelica.Thermal.HeatTransfer.Examples.Motor.mos

TESTFILES_ALL = $(TESTFILES) \
Modelica.Electrical.Analog.Examples.CauerLowPassSC_levelfix.mos \
Modelica.Electrical.Analog.Examples.CauerLowPassSC_tbb.mos \
BouncingBall_mcp_omp.mos \
BouncingBall_levelfix_pthreads.mos \
Modelica.Electrical.Spice3.Examples.CoupledInductors_list_omp.mos \
Modelica.Electrical.Spice3.Examples.CoupledInductors_listr_omp.mos \
Modelica.Electrical.Spice3.Examples.CoupledInductors_list_pthreads.mos \
Modelica.Electrical.Spice3.Examples.CoupledInductors_list_pthreads_spin.mos \
Modelica.Electrical.Spice3.Examples.CoupledInductors_mcp_omp.mos \
Modelica.Electrical.Spice3.Examples.CoupledInductors_tbb.mos \
Modelica.Fluid.Examples.BranchingDynamicPipes_levelfix.mos \
Modelica.Fluid.Examples.DrumBoiler.DrumBoiler_mcp_pthreads.mos \
Modelica.Thermal.HeatTransfer.Examples.Motor.mos


# Run make failingtest
FAILINGTESTFILES= \
Modelica.Mechanics.MultiBody.Examples.Elementary.ThreeSprings_level_omp.mos

# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
*.mos \
*.json \
Makefile \
ReferenceFiles \
ReferenceGraphs


CLEAN = `ls | grep -w -v -f deps.tmp`

.PHONY : test testAll clean getdeps failingtest

test:
	@echo
	@echo Running tests...
	@echo
	@echo OPENMODELICAHOME=" $(OPENMODELICAHOME) "
	@$(TEST) $(TESTFILES)

testAll:
	@echo
	@echo Running all tests...
	@echo
	@echo OPENMODELICAHOME=" $(OPENMODELICAHOME) "
	@$(TEST) $(TESTFILES_ALL)

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
