TEST = ../../rtest -v
BASELINE = ../../rtest -b

TESTMODELS = \
ModelicaDataReconciliationSimpleTests.Models.DistillationTower \
ModelicaDataReconciliationSimpleTests.Models.FourFlows.FourFlows \
ModelicaDataReconciliationSimpleTests.Models.Pipe.Pipe1 \
ModelicaDataReconciliationSimpleTests.Models.Pipe.Pipe2 \
ModelicaDataReconciliationSimpleTests.Models.Pipe.Pipe3 \
ModelicaDataReconciliationSimpleTests.Models.Pipe.Pipe4 \
ModelicaDataReconciliationSimpleTests.Models.Pipe.Pipe5 \
ModelicaDataReconciliationSimpleTests.Models.Pipe.Pipe6 \
ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter \
ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter1 \
ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter2 \
ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter3 \
ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter4 \
ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter5a \
ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter5c \
ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter5e \
ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter5f \
ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter6 \
ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter7 \
ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter9 \
TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows \
TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows1 \
TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows10 \
TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows2 \
TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows3 \
TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows4 \
TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows7 \
TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe \
TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe1 \
TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe10 \
TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe11 \
TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe7 \
TSP_DataReconciliationSimpleTests.Models.Splitter.TSP_Splitter1 \
TSP_DataReconciliationSimpleTests.Models.Splitter.TSP_Splitter2 \
TSP_DataReconciliationSimpleTests.Models.Splitter.TSP_Splitter3 \
TSP_DataReconciliationSimpleTests.Models.Splitter.TSP_Splitter4 \
TSP_DataReconciliationSimpleTests.Models.Splitter.TSP_Splitter5 \
TSP_DataReconciliationSimpleTests.Models.Splitter.TSP_Splitter7 \
TSP_DataReconciliationSimpleTests.Models.Splitter.TSP_Splitter_DR \
TSP_DataReconciliationSimpleTests.Models.StructuralAnalysis.SG_DR_WithHARE \
TSP_DataReconciliationSimpleTests.Models.StructuralAnalysis.PressureLoss_DR_WithHARE

# These are generated from annotations too, but are not passing tests yet:
# - PipeCorrelation reports a solveSystemFstar failure and unstable warning text.
# - Remaining TSP models either fail to build, fail at execution, or report
#   data reconciliation errors.
FAILINGTESTMODELS = \
ModelicaDataReconciliationSimpleTests.Models.Pipe.PipeCorrelation \
ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter0 \
ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter5 \
ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter5b \
ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter5d \
ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter8 \
ModelicaDataReconciliationSimpleTests.Models.VDI2048.VDI2048Example \
ModelicaDataReconciliationSimpleTests.Models.VDI2048.VDI2048Example_Corrected \
TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows5 \
TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows6 \
TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows8 \
TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows9 \
TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe12 \
TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe2 \
TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe3 \
TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe4 \
TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe5 \
TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe6 \
TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe8 \
TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe9 \
TSP_DataReconciliationSimpleTests.Models.Splitter.TSP_Splitter6 \
TSP_DataReconciliationSimpleTests.Models.Splitter.TSP_Splitter8 \
TSP_DataReconciliationSimpleTests.Models.StructuralAnalysis.SG_DR \
TSP_DataReconciliationSimpleTests.Models.StructuralAnalysis.PressureLoss_DR

GENERATED_TESTFILES = $(addsuffix .mos,$(TESTMODELS))
GENERATED_FAILINGTESTFILES = $(addsuffix .mos,$(FAILINGTESTMODELS))

TESTFILES = \
$(GENERATED_TESTFILES)

# test that currently fail. Move up when fixed.
# Run make testfailing
FAILINGTESTFILES = \
$(GENERATED_FAILINGTESTFILES)


# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
*.mos \
*.csv  \
*.txt   \
*.html   \
*.py \
Makefile


CLEAN = `ls | grep -w -v -f deps.tmp`

.PHONY : test clean getdeps failingtest generateModelicaDataReconciliationMos testModelicaDataReconciliation baselineModelicaDataReconciliation

generateModelicaDataReconciliationMos:
	@./generateModelicaDataReconciliationMos.py $(TESTMODELS) $(FAILINGTESTMODELS)

testModelicaDataReconciliation: generateModelicaDataReconciliationMos
	@$(TEST) $(GENERATED_TESTFILES)

baselineModelicaDataReconciliation: generateModelicaDataReconciliationMos
	@$(BASELINE) $(GENERATED_TESTFILES)

test:
	@echo
	@echo Running tests...
	@echo
	@echo OPENMODELICAHOME=" $(OPENMODELICAHOME) "
	@$(TEST) $(TESTFILES)

baseline:
	@echo
	@echo Running baseline for tests...
	@echo
	@echo OPENMODELICAHOME=" $(OPENMODELICAHOME) "
	@$(BASELINE) $(TESTFILES)

failtestbaseline:
	@echo
	@echo Running baseline for failing tests...
	@echo
	@echo OPENMODELICAHOME=" $(OPENMODELICAHOME) "
	@$(MAKE) generateModelicaDataReconciliationMos
	@$(BASELINE) $(FAILINGTESTFILES)

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
	@$(MAKE) generateModelicaDataReconciliationMos
	@$(TEST) $(FAILINGTESTFILES)
