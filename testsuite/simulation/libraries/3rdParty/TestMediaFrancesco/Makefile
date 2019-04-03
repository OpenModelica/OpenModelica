TEST = ../../../../rtest

TESTFILES = \
TestMedia.TestModels.ColdWater.Test1.mos \
TestMedia.TestModels.ColdWater.Test2.mos \
TestMedia.TestModels.ColdWater.Test3.mos \
TestMedia.TestModels.ColdWater.Test4.mos \
TestMedia.TestModels.Nitrogen.Test1.mos \
TestMedia.TestModels.WaterIF97.Test1.mos \
TestMedia.TestModels.WaterIF97.Test2.mos \
TestMedia.TestModels.WaterIF97.Test3.mos \
TestMedia.TestModels.WaterIF97.Test4.mos \
TestMedia.TestModels.WaterIF97.Test5.mos \
TestMedia.TestModels.WaterIF97.Test6.mos \
TestMedia.TestModels.WaterIF97.Test7.mos \
TestMedia.TestModels.WaterIF97.Test8.mos
# test that currently fail. Move up when fixed.
# Run make testfailing
FAILINGTESTFILES=  \
TestMedia.TestModels.FlueGas.Test1.mos \
TestMedia.TestModels.FlueGas.Test2.mos \
TestMedia.TestModels.FlueGas.Test3.mos \
TestMedia.TestModels.FlueGas.Test4.mos \

# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
 *.mo \
 *.mos \
 Makefile \
 ReferenceFiles



CLEAN = `ls | grep -w -v -f deps.tmp`

.PHONY : test clean getdeps

test :
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
	@$(TEST) $(FAILINGTESTFILES) \



