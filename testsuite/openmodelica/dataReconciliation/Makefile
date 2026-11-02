TEST = ../../rtest -v
BASELINE = ../../rtest -b

# The tests are spelled out, runtests.pl only finds test files that are listed
# literally.
TESTFILES = \
ModelicaDataReconciliationSimpleTests.Models.DistillationTower.mos \
ModelicaDataReconciliationSimpleTests.Models.assert.mos \
ModelicaDataReconciliationSimpleTests.Models.FourFlows.FourFlows.mos \
ModelicaDataReconciliationSimpleTests.Models.Pipe.Pipe1.mos \
ModelicaDataReconciliationSimpleTests.Models.Pipe.Pipe2.mos \
ModelicaDataReconciliationSimpleTests.Models.Pipe.Pipe3.mos \
ModelicaDataReconciliationSimpleTests.Models.Pipe.Pipe4.mos \
ModelicaDataReconciliationSimpleTests.Models.Pipe.Pipe5.mos \
ModelicaDataReconciliationSimpleTests.Models.Pipe.Pipe6.mos \
ModelicaDataReconciliationSimpleTests.Models.Pipe.PipeCorrelation.mos \
ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter.mos \
ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter0.mos \
ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter1.mos \
ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter2.mos \
ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter3.mos \
ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter4.mos \
ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter5.mos \
ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter5a.mos \
ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter5b.mos \
ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter5c.mos \
ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter5d.mos \
ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter5e.mos \
ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter5f.mos \
ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter6.mos \
ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter7.mos \
ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter8.mos \
ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter9.mos \
ModelicaDataReconciliationSimpleTests.Models.VDI2048.VDI2048Example.mos \
ModelicaDataReconciliationSimpleTests.Models.VDI2048.VDI2048Example_Corrected.mos \
TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows.mos \
TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows1.mos \
TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows10.mos \
TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows2.mos \
TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows3.mos \
TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows4.mos \
TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows5.mos \
TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows6.mos \
TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows7.mos \
TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows8.mos \
TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows9.mos \
TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe.mos \
TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe1.mos \
TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe10.mos \
TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe11.mos \
TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe12.mos \
TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe2.mos \
TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe3.mos \
TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe4.mos \
TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe5.mos \
TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe6.mos \
TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe7.mos \
TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe8.mos \
TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe9.mos \
TSP_DataReconciliationSimpleTests.Models.Splitter.TSP_Splitter1.mos \
TSP_DataReconciliationSimpleTests.Models.Splitter.TSP_Splitter2.mos \
TSP_DataReconciliationSimpleTests.Models.Splitter.TSP_Splitter3.mos \
TSP_DataReconciliationSimpleTests.Models.Splitter.TSP_Splitter4.mos \
TSP_DataReconciliationSimpleTests.Models.Splitter.TSP_Splitter5.mos \
TSP_DataReconciliationSimpleTests.Models.Splitter.TSP_Splitter6.mos \
TSP_DataReconciliationSimpleTests.Models.Splitter.TSP_Splitter7.mos \
TSP_DataReconciliationSimpleTests.Models.Splitter.TSP_Splitter8.mos \
TSP_DataReconciliationSimpleTests.Models.Splitter.TSP_Splitter_DR.mos \
TSP_DataReconciliationSimpleTests.Models.StructuralAnalysis.PressureLoss_DR.mos \
TSP_DataReconciliationSimpleTests.Models.StructuralAnalysis.PressureLoss_DR_WithHARE.mos \
TSP_DataReconciliationSimpleTests.Models.StructuralAnalysis.SG_DR.mos \
TSP_DataReconciliationSimpleTests.Models.StructuralAnalysis.SG_DR_WithHARE.mos \
UncertainAliasSimulation.mos

# New backend variants of the tests above, see testNB. They are spelled out,
# runtests.pl only finds test files that are listed literally.
NB_TESTFILES = \
NB_ModelicaDataReconciliationSimpleTests.Models.DistillationTower.mos \
NB_ModelicaDataReconciliationSimpleTests.Models.assert.mos \
NB_ModelicaDataReconciliationSimpleTests.Models.FourFlows.FourFlows.mos \
NB_ModelicaDataReconciliationSimpleTests.Models.Pipe.Pipe1.mos \
NB_ModelicaDataReconciliationSimpleTests.Models.Pipe.Pipe2.mos \
NB_ModelicaDataReconciliationSimpleTests.Models.Pipe.Pipe3.mos \
NB_ModelicaDataReconciliationSimpleTests.Models.Pipe.Pipe4.mos \
NB_ModelicaDataReconciliationSimpleTests.Models.Pipe.Pipe5.mos \
NB_ModelicaDataReconciliationSimpleTests.Models.Pipe.Pipe6.mos \
NB_ModelicaDataReconciliationSimpleTests.Models.Pipe.PipeCorrelation.mos \
NB_ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter.mos \
NB_ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter0.mos \
NB_ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter1.mos \
NB_ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter2.mos \
NB_ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter3.mos \
NB_ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter4.mos \
NB_ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter5.mos \
NB_ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter5a.mos \
NB_ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter5b.mos \
NB_ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter5c.mos \
NB_ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter5d.mos \
NB_ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter5e.mos \
NB_ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter5f.mos \
NB_ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter6.mos \
NB_ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter7.mos \
NB_ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter8.mos \
NB_ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter9.mos \
NB_ModelicaDataReconciliationSimpleTests.Models.VDI2048.VDI2048Example.mos \
NB_ModelicaDataReconciliationSimpleTests.Models.VDI2048.VDI2048Example_Corrected.mos \
NB_TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows.mos \
NB_TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows1.mos \
NB_TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows10.mos \
NB_TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows2.mos \
NB_TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows3.mos \
NB_TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows4.mos \
NB_TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows5.mos \
NB_TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows6.mos \
NB_TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows7.mos \
NB_TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows8.mos \
NB_TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows9.mos \
NB_TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe.mos \
NB_TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe1.mos \
NB_TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe10.mos \
NB_TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe11.mos \
NB_TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe12.mos \
NB_TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe2.mos \
NB_TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe3.mos \
NB_TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe4.mos \
NB_TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe5.mos \
NB_TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe6.mos \
NB_TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe7.mos \
NB_TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe8.mos \
NB_TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe9.mos \
NB_TSP_DataReconciliationSimpleTests.Models.Splitter.TSP_Splitter1.mos \
NB_TSP_DataReconciliationSimpleTests.Models.Splitter.TSP_Splitter2.mos \
NB_TSP_DataReconciliationSimpleTests.Models.Splitter.TSP_Splitter3.mos \
NB_TSP_DataReconciliationSimpleTests.Models.Splitter.TSP_Splitter4.mos \
NB_TSP_DataReconciliationSimpleTests.Models.Splitter.TSP_Splitter5.mos \
NB_TSP_DataReconciliationSimpleTests.Models.Splitter.TSP_Splitter6.mos \
NB_TSP_DataReconciliationSimpleTests.Models.Splitter.TSP_Splitter7.mos \
NB_TSP_DataReconciliationSimpleTests.Models.Splitter.TSP_Splitter8.mos \
NB_TSP_DataReconciliationSimpleTests.Models.Splitter.TSP_Splitter_DR.mos \
NB_TSP_DataReconciliationSimpleTests.Models.StructuralAnalysis.PressureLoss_DR.mos \
NB_TSP_DataReconciliationSimpleTests.Models.StructuralAnalysis.PressureLoss_DR_WithHARE.mos \
NB_TSP_DataReconciliationSimpleTests.Models.StructuralAnalysis.SG_DR.mos \
NB_TSP_DataReconciliationSimpleTests.Models.StructuralAnalysis.SG_DR_WithHARE.mos \
NB_UncertainAliasSimulation.mos

# The tests of NB_TESTFILES whose SET-S has an algebraic loop. The jacobian F
# then contains a linear system, which the new backend cannot generate yet,
# and the simulation fails with "residual function pointer is invalid". See
# the TODO at createJacobian in NBDataReconciliation.mo. They keep the failure
# as expected result. Run make testNBJacobianLoops
NB_JACOBIAN_LOOP_TESTFILES = \
NB_ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter5e.mos \
NB_ModelicaDataReconciliationSimpleTests.Models.Splitter.Splitter5f.mos \
NB_TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows.mos \
NB_TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows1.mos \
NB_TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows3.mos \
NB_TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows7.mos \
NB_TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows9.mos \
NB_TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe7.mos \
NB_TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe8.mos \
NB_TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe10.mos \
NB_TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe11.mos \
NB_TSP_DataReconciliationSimpleTests.Models.Pipe.TSP_Pipe12.mos \

# The tests of NB_TESTFILES that fail in the initialization of the reconciled
# system: NBTearing fails with "UnorderedMap.getSafe failed because the key did
# not exist". They keep the failure as expected result. Run make testNBInitialization
NB_INITIALIZATION_TESTFILES = \
NB_TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows2.mos \
NB_TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows5.mos \

# The tests of NB_TESTFILES that fail in NSimCode because the tuple equation of
# Water_sat_P is not solved (Solve.UNPROCESSED). They keep the failure as
# expected result. Run make testNBTupleEquations
NB_TUPLE_EQUATION_TESTFILES = \
NB_TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows4.mos \
NB_TSP_DataReconciliationSimpleTests.Models.FourFlows.TSP_FourFlows6.mos \
NB_TSP_DataReconciliationSimpleTests.Models.Splitter.TSP_Splitter5.mos \
NB_TSP_DataReconciliationSimpleTests.Models.Splitter.TSP_Splitter8.mos \

# Tests that fail and cannot be part of the testsuite (crash, hang, ...).
# Models that fail in a reproducible way go in TESTFILES instead, with the
# failure recorded as the expected result, see #15384.
# Run make failingtest
FAILINGTESTFILES= \


# Files that are not generated by the tests. The libraries and their input
# files come from OpenModelica/DataReconciliationLibraries, installed by
# libs-for-testing. Add them here or they will be cleaned.
DEPENDENCIES = \
*.mos \
Makefile \

CLEAN = `ls | grep -x -v -f deps.tmp`

.PHONY : test testNB testNBJacobianLoops testNBInitialization testNBTupleEquations baselineNB clean getdeps failingtest

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

testNB:
	@echo
	@echo Running new backend tests...
	@echo
	@echo OPENMODELICAHOME=" $(OPENMODELICAHOME) "
	@$(TEST) $(NB_TESTFILES)

testNBJacobianLoops:
	@echo
	@echo Running new backend tests with loops in the jacobian F...
	@echo
	@echo OPENMODELICAHOME=" $(OPENMODELICAHOME) "
	@$(TEST) $(NB_JACOBIAN_LOOP_TESTFILES)

testNBInitialization:
	@echo
	@echo Running new backend tests that fail in the initialization...
	@echo
	@echo OPENMODELICAHOME=" $(OPENMODELICAHOME) "
	@$(TEST) $(NB_INITIALIZATION_TESTFILES)

testNBTupleEquations:
	@echo
	@echo Running new backend tests that fail with an unsolved tuple equation...
	@echo
	@echo OPENMODELICAHOME=" $(OPENMODELICAHOME) "
	@$(TEST) $(NB_TUPLE_EQUATION_TESTFILES)

baselineNB:
	@echo
	@echo Running baseline for new backend tests...
	@echo
	@echo OPENMODELICAHOME=" $(OPENMODELICAHOME) "
	@$(BASELINE) $(NB_TESTFILES)

failtestbaseline:
	@echo
	@echo Running baseline for failing tests...
	@echo
	@echo OPENMODELICAHOME=" $(OPENMODELICAHOME) "
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
	@$(TEST) -disabled $(FAILINGTESTFILES)
