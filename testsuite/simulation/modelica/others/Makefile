TEST = ../../../rtest -v

TESTFILES = \
world.mos \
EngineV6_evalParams.mos \
EngineV6_output.mos \
Bug1687.mos \
Bug1728.mos \
Bug1987.mos \
Bug2432.mos \
Bug2536.mos \
Bug2633.mos \
Bug2704.mos \
Bug2788.mos \
Bug2833.mos \
Bug3023.mos \
Bug3261.mos \
Bug3323.mos \
Bug3500.mos \
Bug3687.mos \
BugTest1830.mos \
ChangeCorrect.mos \
CombiTable1DBug.mos \
ComplexAlgebraicLoop.mos \
ComplexFun.mos \
DiscreteVectorStateSpace.mos \
Elevator.mos \
EquationCallIntegerArray.mos \
ExtendsBasic.mos  \
FrameTest.mos \
IdealDiode.mos  \
impureTest.mos \
NoLoadModel.mos \
nonConstantIndex.mos \
nonConstantParam.mos \
ParameterCycle.mos \
ParameterModel.mos \
Pendulum.mos \
PreAndAliasedVar.mos \
PreMatrix.mos \
Random.mos \
Random2.mos \
Reductions.mos \
Riccati.mos \
sample1.mos \
sample2.mos \
sample3.mos \
SimResultScripting.mos \
simulation.mos \
SliceAssignment.mos \
steadyState.mos \
StringTest.mos \
SyncFilter.mos \
Switch.mos \
Table2d.mos \
terminal.mos \
TestAsub.mos \
tempInterpol2test.mos \
TestLapack.mos \
TestExpressionSolve.mos \
TestNormVar.mos \
TestSolve.mos \
TestSolve2.mos \
TestSolve3.mos \
TestSolve4.mos \
TestSolve5.mos \
TestSolve6.mos \
TestSolve7.mos \
TestSolve8.mos \
TestSolve9.mos \
TestSolve10.mos \
TestSolve11.mos \
TestSolve12.mos \
TestSolve13.mos \
TestSolve14.mos \
TestSolve15.mos \
TestSolve16.mos \
TestSolve17.mos \
TestSolve18.mos \
Ticket5129.mos \
VariableFilter.mos \
WhenStatement4.mos \
localKnownVars.mos


# test that currently fail. Move up when fixed. 
# Run make testfailing
FAILINGTESTFILES= \
MoonAndEarth.mos \
pendulum4.mos \
SpaceProbe.mos \
filterTest.mos \
Bug1048.mos \

# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
*.mos \
Makefile \
Table2d.txt \
testTables2.csv \
testTables2.txt \
testTables2D.txt \
Bug1048.mat


CLEAN = `ls | grep -w -v -f deps.tmp`

.PHONY : test clean getdeps

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
