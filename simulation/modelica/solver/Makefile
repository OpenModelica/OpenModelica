TEST = ../../../rtest -v

TESTFILES = \
bug2231-radau1.mos \
LotkaVolterraWithInput.mos \
problem1-dasslsteps.mos \
problem1-impeuler.mos \
problem1-trapezoid.mos \
problem1-imprk.mos \
problem1-irksco.mos \
problem1-ida.mos \
problem1-symSolverImp.mos \
problem1-symSolverExp.mos \
problem1-symSolverImpSsc.mos \
problem1-symSolverExpSsc.mos \
problem2-dasslsteps.mos \
problem2-impeuler.mos \
problem2-trapezoid.mos \
problem2-imprk.mos \
problem2-irksco.mos \
problem2-ida.mos \
problem2-idaLinearSolver.mos \
problem2-idaJacobian.mos \
problem2-imprkLS.mos \
problem2-symSolverImp.mos \
problem2-symSolverExp.mos \
problem2-symSolverImpSsc.mos \
problem2-symSolverExpSsc.mos \
problem3-symSolverImp.mos \
problem3-symSolverExp.mos \
problem3-symSolverImpSsc.mos \
problem3-symSolverExpSsc.mos \
problem4-erk_ssc.mos \
problem4-symSolverImp.mos \
problem4-symSolverExp.mos \
problem5-symSolverImp.mos \
problem5-symSolverExp.mos \
problem6-irksco.mos \
problem6-symSolverImp.mos \
problem6-symSolverExp.mos \

# run only symSolver tests
SYMSOLVER = \
problem1-symSolverImp.mos \
problem1-symSolverExp.mos \
problem1-symSolverImpSsc.mos \
problem1-symSolverExpSsc.mos \
problem2-symSolverImp.mos \
problem2-symSolverExp.mos \
problem2-symSolverImpSsc.mos \
problem2-symSolverExpSsc.mos \
problem3-symSolverImp.mos \
problem3-symSolverExp.mos \
problem3-symSolverImpSsc.mos \
problem3-symSolverExpSsc.mos \
problem4-symSolverImp.mos \
problem4-symSolverExp.mos \
problem5-symSolverImp.mos \
problem5-symSolverExp.mos \
problem6-symSolverImp.mos \
problem6-symSolverExp.mos \

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
	rm -rf externalInput.csv
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

symSolver:
	@echo
	@echo Running tests...
	@echo
	@echo OPENMODELICAHOME=" $(OPENMODELICAHOME) "
	@$(TEST) $(SYMSOLVER)
