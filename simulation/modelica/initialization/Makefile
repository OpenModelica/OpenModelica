TEST = ../../../rtest -v

TESTFILES = \
array_algorithm.mos \
boundParameterExpUnfixed.mos \
bug_2207.mos \
bug_2263.mos \
bug_2504.mos \
bug_2566.mos \
bug_2583.mos \
bug_2673.mos \
bug_2673b.mos \
bug_2830.mos \
bug_2990.mos \
bug_2994.mos \
bug_3014.mos \
bug_3052.mos \
bug_3536.mos \
bug_4387.mos \
bug_4718.mos \
discreteTest01.mos \
discreteTest02.mos \
discreteTest03.mos \
discreteTest04.mos \
discreteTest05.mos \
discreteTest06.mos \
discreteTest08.mos \
discreteTest09.mos \
discreteTest10.mos \
eventTest.mos \
eventTest2.mos \
filterBlock1.mos \
fullRobot.mos \
gaspropreties.mos \
homotopy1.mos \
homotopy2.mos \
homotopy3.mos \
homotopy4.mos \
homotopy4_solver.mos \
homotopy5.mos \
initial_equation.mos \
parameters.mos \
parameterWithoutBinding.mos \
pre1.mos \
pre2.mos \
pre3.mos \
scaling1.mos \
scaling2.mos \
SingularInitial.mos \
singularJacobian.mos \
startValue.mos \
startValue1.mos \
startValue2.mos \
startValue3.mos \
terminate.mos \
testIfAssert.mos \
underdeterminedTest1.mos \
underdeterminedTest2.mos \
underdeterminedTest3.mos \
underdeterminedTest4.mos \
underdeterminedTest5.mos \
underdeterminedTest6.mos \
unfixedParameter1.mos \
unfixedParameter2.mos \
autoFixed.mos \
OverdeterminedInitialization.Electrical.Test3PhaseSystemsFullInitial.mos \
OverdeterminedInitialization.Fluid.DynamicPipeInitialValues.mos \
OverdeterminedInitialization.Fluid.DynamicPipeLumpedPressureInitialization.mos \
OverdeterminedInitialization.Fluid.DynamicPipesSeriesLargeNSteadyStateInitial.mos \
OverdeterminedInitialization.Fluid.DynamicPipesSeriesSteadyStateInitial.mos \
OverdeterminedInitialization.Fluid.TwoVolumesEquationsFullInitial.mos \
OverdeterminedInitialization.Fluid.TwoVolumesEquationsFullInitialInconsistent.mos \
OverdeterminedInitialization.Fluid.TwoVolumesEquationsFullSteadyStateMassAndEnergy.mos \
OverdeterminedInitialization.Fluid.TwoVolumesEquationsFullSteadyStatePressureAndTemperature.mos \
OverdeterminedInitialization.Mechanical.TwoMassesEquationsFullInitial.mos \
OverdeterminedInitialization.Mechanical.TwoMassesEquationsFullInitialInconsistent.mos \
OverdeterminedInitialization.Mechanical.TwoMassesEquationsFullSteadyState.mos \
OverdeterminedInitialization.Mechanical.TwoMassesFullInitial.mos \
OverdeterminedInitialization.Mechanical.TwoMassesFullInitialInconsistent.mos \
OverdeterminedInitialization.Mechanical.TwoMassesFullSteadyState.mos \
OverdeterminedInitialization.Fluid.TwoVolumesFullInitialInconsistent.mos \
OverdeterminedInitialization.Fluid.TwoVolumesFullInitial.mos \
OverdeterminedInitialization.Fluid.TwoVolumesFullSteadyStatePressureAndTemperature.mos \
redundantInitialEquations.mos \
conflictingStartValues.mos \
conflictingStartValues2.mos \
Ticket5340.mos \


# test that currently fail. Move up when fixed.
# Run make failingtest
FAILINGTESTFILES = \
discreteTest07.mos \


# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
*.mos \
Makefile \

CLEAN = `ls | grep -w -v -f deps.tmp`

.PHONY : test clean getdeps failingtest

test:
	@echo
	@echo Running tests...
	@echo
	@echo OPENMODELICAHOME=" $(OPENMODELICAHOME) "
	@$(TEST) $(TESTFILES)

# Cleans all files that are not listed as dependencies
clean:
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
