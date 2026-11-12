TEST = ../../../../rtest -v

TESTFILES = \
CvodeDefault.mos \
ExportCvodeFmu_cmake.mos \
ExportCvodeFmu_dynamic.mos \
ExportCvodeFmu_static.mos \
fmi2_log_categories.mos \
fmi_interpolation_01.mos \
FmuAssertSolverRetry.mos \
FmuEquationAssertLog.mos \
FmuExitInitAssert.mos \
FmuMatV7Table.mos \
FmuZlibLinkOrder.mos \
FmuNlsSameTime.mos \
FmuUnknownDependencies.mos \
FmuUnknownsWithoutFmiIndex.mos \
FmuExportFlags.mos \
RecompileSourceCodeFMU.mos \
simpleStiffFMU.mos \
issue10523.mos \
Issue14456.mos \
CvodeStepTooClose.mos \
Issue17436.mos \
FmuStartEventError.mos \

# test that currently fail. Move up when fixed.
# Run make testfailing
FAILINGTESTFILES = \

# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
*.mos \
fmi2_log_categories.py \
FmuAssertSolverRetry.py \
FmuEquationAssertLog.py \
FmuExitInitAssert.py \
FmuNlsSameTime.py \
FmuStartEventError.py \
FmuZlibLinkOrder-f.c \
Makefile \

CLEAN = `ls | grep -w -v -f deps.tmp`

.PHONY : test clean getdeps

test:
	@echo
	@echo Running tests...
	@echo
	@echo OPENMODELICAHOME=" $(OPENMODELICAHOME) "
	@$(TEST) $(TESTFILES)

baseline:
	@echo
	@echo Updating badelines...
	@echo
	@echo OPENMODELICAHOME=" $(OPENMODELICAHOME) "
	@$(TEST) -b $(TESTFILES)

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
	@$(TEST) -disabled $(FAILINGTESTFILES)
