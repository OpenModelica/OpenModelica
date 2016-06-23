TEST = ../../../rtest -v

TESTFILES = \
bug2231-radau1.mos \
LotkaVolterraWithInput.mos \
problem1-dasslsteps.mos \
problem1-radau1.mos \
problem1-radau3.mos \
problem1-radau5.mos \
problem1-lobatto2.mos \
problem1-lobatto4.mos \
problem1-lobatto6.mos \
problem1-symEuler.mos \
problem1-ida.mos \
problem2-dasslsteps.mos \
problem2-radau1.mos \
problem2-radau3.mos \
problem2-radau5.mos \
problem2-lobatto2.mos \
problem2-lobatto4.mos \
problem2-lobatto6.mos \
problem2-symEuler.mos \
problem2-ida.mos \
problem2-idaLinearSolver.mos \
problem3-symEuler.mos

#runonly DAE tests
DAETESTFILES = \
testDAEp1.mos \
testDAEp2.mos \
testDAEp3.mos \
testDAEp4.mos \
testDAEp5.mos \
testDAEmodeDrumBoiler.mos


# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
*.mos \
Makefile \


CLEAN = `ls | grep -w -v -f deps.tmp`

.PHONY : test testDAE clean getdeps

test:
	@echo
	@echo Running tests...
	@echo
	@echo OPENMODELICAHOME=" $(OPENMODELICAHOME) "
	rm -rf externalInput.csv
	@$(TEST) $(TESTFILES)

testDAE:
	@echo
	@echo Running DAE tests...
	@echo
	@echo OPENMODELICAHOME=" $(OPENMODELICAHOME) "
	@$(TEST) $(DAETESTFILES)

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
