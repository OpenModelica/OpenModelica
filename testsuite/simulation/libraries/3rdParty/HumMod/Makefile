TEST = ../../../../rtest -v

TESTFILES = \
buildHumModOMC.mos \
checkHumModOMC.mos

# test that currently fail. Move up when fixed.
# Run make testfailing
FAILINGTESTFILES= \
xxx.mos

# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
HumMod \
Physiolibrary \
*.mo \
*.mos \
*.sed \
HumMod_License.txt \
Makefile

CLEAN = `ls | grep -w -v -f deps.tmp`

TransformSedFile := toOMCandMODELICA_STANDARD.sed
export RTEST_OMCFLAGS := +d=nogen

.PHONY : test clean getdeps failingtest hmtr_toOMC mkdir_forOMC

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

failingtest : hmtr_toOMC
	@echo RTEST_OMCFLAGS = $(RTEST_OMCFLAGS)
	@echo
	@echo Running failing tests...
	@echo
	@$(TEST) $(FAILINGTESTFILES)

hmtr_toOMC: mkdir_forOMC
	@sed -f $(TransformSedFile) <./HumMod/package.mo >./HumMod_OMC/HumMod/package.mo
	@sed -f $(TransformSedFile) <./Physiolibrary/package.mo >./HumMod_OMC/Physiolibrary/package.mo

mkdir_forOMC:
	@mkdir -p ./HumMod_OMC/HumMod
	@mkdir -p ./HumMod_OMC/Physiolibrary
	@(cp -pfu ./HumMod/package.encoding  ./HumMod_OMC/HumMod/)
	@(cp -pfu ./Physiolibrary/package.encoding  ./HumMod_OMC/Physiolibrary/)
#	(cp -pfu ./Physiolibrary/package.order  ./HumMod_OMC/Physiolibrary/)

