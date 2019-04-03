TEST = ../../../rtest -v

TESTFILES = \
Tearing1-celMC3.mos \
Tearing2-celMC3.mos \
Tearing3-celMC3.mos \
Tearing4-celMC3.mos \
Tearing5-celMC3.mos \
Tearing6-celMC3.mos \
Tearing7-celMC3.mos \
Tearing8-celMC3.mos \
Tearing8-celMC3sorted.mos \
Tearing9-celMC3.mos \
Tearing10-celMC11.mos \
Tearing10-celMC12.mos \
Tearing10-celMC13.mos \
Tearing10-celMC21.mos \
Tearing10-celMC22.mos \
Tearing10-celMC23.mos \
Tearing10-celMC231.mos \
Tearing10-celMC3.mos \
Tearing10-celMC4.mos \
Tearing11-celMC3.mos \
Tearing12-celMC3.mos \
Tearing13-celMC3.mos \
Tearing14-celMC3.mos \
Tearing15-celMC3.mos \
Tearing16-celMC3.mos \
Algorithm1-celMC3.mos \
Algorithm2-celMC3.mos \
MixedTearing1-celMC3.mos \
tearingSelect-celMC3.mos \
tearingSelect2-celMC3.mos \
dynamicTearing1.mos \
dynamicTearing2.mos \
dynamicTearing3.mos \
Tearing1-cel.mos \
Tearing2-cel.mos \
Tearing3-cel.mos \
Tearing4-cel.mos \
Tearing5-cel.mos \
Tearing6-cel.mos \
Tearing7-cel.mos \
Tearing8-cel.mos \
Tearing9-cel.mos \
Tearing10-cel.mos \
Tearing11-cel.mos \
Tearing12-cel.mos \
Tearing13-cel.mos \
Tearing14-cel.mos \
Tearing15-cel.mos \
Tearing16-cel.mos \
Tearing19-cel.mos \
Algorithm1-cel.mos \
Algorithm2-cel.mos \
MixedTearing1-cel.mos \
Tearing1-omc.mos \
Tearing2-omc.mos \
Tearing3-omc.mos \
Tearing4-omc.mos \
Tearing5-omc.mos \
Tearing6-omc.mos \
Tearing7-omc.mos \
Tearing8-omc.mos \
Tearing9-omc.mos \
Tearing10-omc.mos \
Tearing11-omc.mos \
Tearing12-omc.mos \
Tearing13-omc.mos \
Tearing14-omc.mos \
Tearing15-omc.mos \
Tearing16-omc.mos \
Algorithm1-omc.mos \
Algorithm2-omc.mos \
MixedTearing1-omc.mos \
tearingSelect-omc.mos \
tearingSelect2-omc.mos \
totalTearing1.mos \
totalTearing2.mos \
totalTearing3.mos \
userDefinedTearing1.mos \
userDefinedTearing2.mos \
testTearingStrictness.mos \
testParamDivision.mos \




# test that currently fail. Move up when fixed. 
# Run make testfailing
FAILINGTESTFILES = \
Tearing17-omc.mos \
Tearing18-omc.mos \
Tearing17-cel.mos \
Tearing18-cel.mos \
Tearing17-celMC3.mos \
Tearing18-celMC3.mos \

# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
*.mos \
*.sh \
Makefile


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
