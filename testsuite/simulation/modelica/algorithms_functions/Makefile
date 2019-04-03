TEST = ../../../rtest -v

TESTFILES = \
AlgorithmCondAssign1.mos \
AlgorithmCondAssign2.mos \
AlgorithmForInClass.mos \
algorithms.mos \
AlgorithmSection.mos \
AlgorithmSize.mos \
AlgorithmTupleAssign.mos \
ArrayInitSorting.mos \
ASubIfExp.mos \
bug_2452.mos \
bug_2271.mos \
bug_2286.mos \
bug_2286_literal.mos \
bug2888.mos \
ComplexSystem.mos \
DoubleWhenSequential.mos \
ForIterator1.mos \
ForIterator2.mos \
FuncDer.mos  \
FunctionIndirectRecursion.mos \
FunctionIndirectRecursion2.mos \
FunctionInReinit.mos \
FunctionTupleRecord.mos \
Interpolation.mos \
InverseAlgorithm1.mos \
InverseAlgorithm2.mos \
InverseAlgorithm3.mos \
InverseAlgorithm4.mos \
LocalVariableInit.mos \
ModelicaTest.Fluid.Dissipation.Verifications.HeatTransfer.Channel.kc_evenGapLaminar.mos \
SimplePeriodicSampler.mos \
SumSeriesWhile.mos \
TestCrossFunction.mos \
ticket-3477.mos \
TupleReturn.mos \
val.mos \
whenDiscreteForLoop.mos \
whenFunctionTuple.mos \
WhenPriority.mos \
WhenStatement1.mos \
WhenStatement2.mos \
WhenStatement3.mos \
whenstatements.mos \
ZeroCross.mos \

# test that currently fail. Move up when fixed.
# Run make testfailing
FAILINGTESTFILES = \
StatementCall.mos \

# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
*.mos \
Makefile \

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
