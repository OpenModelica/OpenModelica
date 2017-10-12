TEST = ../../../rtest -v

TESTFILES = \
bug_2841.mos \
bug_3527.mos \
nanTest.mos \
nonlinear.mos \
nonlinear_kinsol.mos \
nonlinearDelayTest.mos \
nonlinearFailed.mos \
nonlinearFailed_kinsol.mos \
nonlinearMixed.mos \
nonlinearMixed_kinsol.mos \
problem1.mos \
problem1_kinsol.mos \
problem1_newton.mos \
problem1_symjac.mos \
problem1_symjac_tearing.mos \
problem2.mos \
problem2_newton.mos \
problem2_symjac.mos \
problem2_symjac_tearing.mos \
problem3.mos \
problem3_kinsol.mos \
problem3_newton.mos \
problem3_symjac.mos \
problem3_symjac_tearing.mos \
problem4.mos \
problem4_symjac.mos \
problem4_symjac_tearing.mos \
problem5.mos \
problem5_newton.mos \
problem6.mos \
problem6_kinsol.mos \
problem6_newton.mos \
problem6_symjac.mos \
problem6_symjac_tearing.mos \
problem7.mos \
problem7_kinsol.mos \
problem7_newton.mos \
problem7_symjac.mos \
problem7_symjac_tearing.mos \
problem8_newton.mos \
problem9.mos \
problem10.mos \
problem11.mos \
problem12.mos \
TestInputIteration.mos \
TestFalseIterationNLS.mos \
ScalingTest1.mos \
inverseTest.mos \

# test that currently fail. Move up when fixed. 
# Run make testfailing
FAILINGTESTFILES= \
fullRobot.mos \
nanTest_kinsol.mos \
nonlinearDelayTest_kinsol.mos \
problem2_kinsol.mos \
problem4_kinsol.mos \
problem4_newton.mos \
problem5_kinsol.mos \
problem5_symjac.mos \
problem5_symjac_tearing.mos \
NonlinearSolverFailureInitial.mos \
NonlinearSolverSimulation.mos \
FiniteEscapeTime.mos \
WrongInitialSolutionSelected.mos

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
