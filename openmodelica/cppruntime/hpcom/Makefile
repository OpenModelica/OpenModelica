TEST = ../../../rtest -v

TESTFILES = \
Modelica.Electrical.Analog.Examples.CauerLowPassSC_levelfix_pthreads_memory.mos \
Modelica.Electrical.Analog.Examples.CauerLowPassSC_level_omp_measureTime.mos \
Modelica.Electrical.Spice3.Examples.CoupledInductors_level_omp.mos \
Modelica.Electrical.Spice3.Examples.CoupledInductors_list_pthreads_spin.mos

TESTFILES_ALL = $(TESTFILES_SERIAL) $(TESTFILES_LEVELFIX) $(TESTFILES_LEVEL) $(TESTFILES_METIS) $(TESTFILES_LIST) $(TESTFILES_LISTR) $(TESTFILES_TBB) $(TESTFILES_MCP)

TESTFILES_SERIAL = \
Modelica.Electrical.Analog.Examples.CauerLowPassSC_serial_omp.mos \
Modelica.Electrical.Analog.Examples.CauerLowPassSC_serial_pthreads.mos

TESTFILES_LEVELFIX = \
Modelica.Electrical.Analog.Examples.CauerLowPassSC_levelfix_pthreads.mos \
Modelica.Electrical.Analog.Examples.CauerLowPassSC_levelfix_pthreads_memory.mos \
Modelica.Fluid.Examples.BranchingDynamicPipes_levelfix_pthreads.mos

TESTFILES_LEVEL = \
Modelica.Electrical.Spice3.Examples.CoupledInductors_level_omp.mos \
Modelica.Electrical.Analog.Examples.CauerLowPassSC_level_omp.mos \
Modelica.Electrical.Analog.Examples.CauerLowPassSC_level_omp_measureTime.mos

TESTFILES_METIS = \
Modelica.Electrical.Analog.Examples.CauerLowPassSC_metis_pthreads.mos

TESTFILES_LIST = \
Modelica.Electrical.Spice3.Examples.CoupledInductors_list_omp.mos \
Modelica.Electrical.Spice3.Examples.CoupledInductors_list_pthreads.mos \
Modelica.Electrical.Spice3.Examples.CoupledInductors_list_pthreads_spin.mos

TESTFILES_LISTR = \
Modelica.Electrical.Spice3.Examples.CoupledInductors_listr_omp.mos

TESTFILES_TBB = \
Modelica.Electrical.Spice3.Examples.CoupledInductors_tbb.mos \
Modelica.Electrical.Analog.Examples.CauerLowPassSC_tbb.mos

TESTFILES_MCP = \
Modelica.Fluid.Examples.DrumBoiler.DrumBoiler_mcp_pthreads.mos \
Modelica.Electrical.Spice3.Examples.CoupledInductors_mcp_omp.mos \
Modelica.Thermal.HeatTransfer.Examples.Motor_mcp_omp.mos

# Run make failingtest
FAILINGTESTFILES= \
Modelica.Mechanics.MultiBody.Examples.Elementary.ThreeSprings_level_omp.mos \
Modelica.Mechanics.MultiBody.Examples.Elementary.ThreeSprings_list_omp.mos \
Modelica.Electrical.Analog.Examples.CauerLowPassSC_level_omp_memory.mos \
Modelica.Thermal.HeatTransfer.Examples.Motor_mcp_omp.mos
# Modelica.Thermal.HeatTransfer.Examples.Motor_mcp_omp.mos fails due to timeout on docker containers

# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
*.mos \
Makefile \
ReferenceFiles \
ReferenceGraphs \
fmu


CLEAN = `ls | grep -w -v -f deps.tmp`

.PHONY : test testAll clean getdeps failingtest testSerial testLevelfix testMetis testList testListr testTbb testMcp

test:
	@echo
	@echo Running tests...
	@echo
	@echo OPENMODELICAHOME=" $(OPENMODELICAHOME) "
	@$(TEST) $(TESTFILES)

testSerial:
	@$(TEST) $(TESTFILES_SERIAL)

testLevelfix:
	@$(TEST) $(TESTFILES_LEVELFIX)

testLevel:
	@$(TEST) $(TESTFILES_LEVEL)

testMetis:
	@$(TEST) $(TESTFILES_METIS)

testList:
	@$(TEST) $(TESTFILES_LIST)

testListr:
	@$(TEST) $(TESTFILES_LISTR)

testTbb:
	@$(TEST) $(TESTFILES_TBB)

testMcp:
	@$(TEST) $(TESTFILES_MCP)

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
