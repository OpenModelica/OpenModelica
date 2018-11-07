TEST = ../../rtest -v

TESTFILES = \
tearnonlin1.mos \
WhenStatement1.mos \
WhenTuple.mos \
BouncingBall.mos \
arraySliceTest.mos \
clockedAlgloopTest.mos \
clockedEventTest.mos \
clockedSolverTest.mos \
clockedTypesTest.mos \
clockedTest.mos \
externalArrayInputTest.mos \
mathFunctionsTest.mos \
nameClashTest.mos \
functionPointerTest.mos \
recordTupleReturnTest.mos \
RefArrayDim2.mos \
solveTest.mos \
testArrayEquations.mos \
testMatrixIO.mos \
testVectorizedBlocks.mos \
testVectorizedPowerSystem.mos \
trapezoidTest.mos

FAILINGTESTFILES= \
ClockInterval.mos \

# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
*.mos \
FlatParse.mof \
Makefile \
EventTests.mat \
ExtObj.c \
ExtObj.h \
ExtObjStringParam.ext.c \
ExtObjStringParam.ext.h \
ExternalFunc1.c \
ExternalFunc1_ext.h \
ExternalFunc2.c \
ExternalFunc2.h \
Func.c \
Func.h \
InOutStrings_fkn1.cc \
InOutStrings_fkn2.cc \
ModelicaUtilities.myExtFunction.c \
dependencies.dep \
testTables.txt \
testTables2.csv \
testTables2.txt \
testTables2D.txt \
hpcom \
fmu \
staticLinking \
genDebugSymbols \
hardcodedStartValues \
outputFormat \
ReferenceFiles \
outputFormat \
libraries \
peer \
omedit

CLEAN = `ls | grep -w -v -f deps.tmp`
HPCOM_DIR = hpcom/
HPCOM_FMI_1_0_DIR = hpcom/fmu/modelExchange/1.0
FMI_1_0_DIR = fmu/modelExchange/1.0
FMI_2_0_DIR = fmu/modelExchange/2.0
STATIC_LINKING_DIR = staticLinking
DEBUG_SYMBOLS_DIR = genDebugSymbols
HARDCODED_START_VALUES_DIR = hardcodedStartValues
OUTPUT_FORMAT_DIR = outputFormat
OMEDIT_DIR = omedit

.PHONY : test clean getdeps failingtest

test:
	@echo
	@echo Running tests...
	@echo
	@echo OPENMODELICAHOME=" $(OPENMODELICAHOME) "
	@$(TEST) $(TESTFILES)
	@$(MAKE) -C $(HPCOM_DIR)
	@$(MAKE) -C $(FMI_1_0_DIR)
	@$(MAKE) -C $(FMI_2_0_DIR)
	@$(MAKE) -C $(HPCOM_FMI_1_0_DIR)
	@$(MAKE) -C $(STATIC_LINKING_DIR)
	@$(MAKE) -C $(DEBUG_SYMBOLS_DIR)
	@$(MAKE) -C $(HARDCODED_START_VALUES_DIR)
	@$(MAKE) -C $(OUTPUT_FORMAT_DIR)
	@$(MAKE) -C $(OMEDIT_DIR)


# Cleans all files that are not listed as dependencies 
clean :
	@echo $(DEPENDENCIES) | sed 's/ /\\|/g' > deps.tmp
	@rm -f $(CLEAN)
	@$(MAKE) -C $(HPCOM_DIR) clean
	@$(MAKE) -C $(FMI_1_0_DIR) clean
	@$(MAKE) -C $(FMI_2_0_DIR) clean
	@$(MAKE) -C $(HPCOM_FMI_1_0_DIR) clean
	@$(MAKE) -C $(STATIC_LINKING_DIR) clean
	@$(MAKE) -C $(DEBUG_SYMBOLS_DIR) clean
	@$(MAKE) -C $(HARDCODED_START_VALUES_DIR) clean
	@$(MAKE) -C $(OUTPUT_FORMAT_DIR) clean
	@$(MAKE) -C $(OMEDIT_DIR) clean


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
