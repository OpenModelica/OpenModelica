TEST = ../../../rtest -v

TESTFILES = \
Array1.mos \
BaseClass1.mos \
cat.mos \
ComplexConnect.mos \
DuplicateDefinition.mos \
DuplicateFunctions.mos \
EnzMM.mos \
ErrorFunctionCallNumArgs.mos \
ErrorSimPackage.mos \
ExtendsOrder.mos \
ExternalFunctionResultOrder.mos\
ExternalLibraryFunction.mos\
FinalTests.mos \
FuncNamespace.mos \
FunctionDefaultArg.mos \
GroupImport.mos \
IntMulOverflow.mos IntPowOverflow.mos IntDivOverflow.mos IntAddSubOverflow.mos \
ISO-8859-1.mos \
LeastSquares.mos \
LookupBuiltin.mos \
LookupPackageFail.mos \
Model1.mos \
Model2.mos \
ModifierVariabilityError.mos \
NotbasicType.mos NotbasicType2.mos \
OverloadingFunc.mos \
QuotedFunction.mos \
Return.mos \
StringArrayReturn.mos \
TestLoadModel.mos \
UnpOpPrecedence.mos \
UnusedVariable.mos \
WhileStatement.mos WhileStatementIllegal.mos \
ModifierProblem.mos \
TransformerYY.mos \
AIMC_DOL.mos \
ZeroDims.mos \
ZeroRange.mos \
vaporizing.mos

# test that currently fail. Move up when fixed.
# Run make testfailing
FAILINGTESTFILES = \

# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
*.mos \
Makefile \
TestLibrary \
ext_ExternalFunctionResultOrder.c \
ISO-8859-1.mox


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
	@rm -rf $(CLEAN)

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
