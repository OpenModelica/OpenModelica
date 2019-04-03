TEST = ../../../rtest -v

TESTFILES = \
ABCDsystem.plt.mos \
ABCDsystem.csv.mos \
ABCDsystem.empty.mos \
AlgorithmArrayEqn.mos \
AppendElement.mos \
ArrayAddSub1.mos \
ArrayDivError.mos \
ArrayExponentiation.mos \
ArrayEquation.mos \
ArrayMult.mos \
ArrayFromRange.mos \
ArrayReduce.mos \
ArrayReturn.mos \
ArrayParameterSize.mos \
ArrayModel.mos \
ArraySlice.mos \
ArraySlice2.mos \
ArraySliceAssigmentFunction.mos \
AsubCrefExpType.mos \
BooleanArray.mos \
BooleanArray2.mos \
Breaker_total.mos \
bug_2217.mos \
bug_2911.mos \
bug_3184.mos \
Bug3187.mos \
ConstructFunc.mos \
crefIndex.mos \
gc.mos \
gc2980.mos \
DimConvert.mos \
NPendulum.mos \
PolynomialEvaluatorA.mos \
PolynomialEvaluatorB.mos \
PolynomialEvaluator1.mos \
PolynomialEvaluator2.mos \
PolynomialEvaluator3.mos \
ticket2336.mos \
ticket5114.mos \
VariableRangeSubscript.mos \
VectorizeOneReturnValue.mos \
Xpowers1.mos \
Xpowers2.mos \
Xpowers3.mos \
ZeroSizeLoop.mos \
Bug3916.mos

# test that currently fail. Move up when fixed. 
# Run make testfailing
FAILINGTESTFILES= \
ArrayFieldSlice.mos \
bug_2300.mos \

# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
*.mos \
Makefile \
ReferenceFiles



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
