TEST = ../../../../../rtest -v


TESTFILES = \
DIC_FMU1_CPP.mos \
Crane_FMU1_CPP.mos

FAILINGTESTFILES = \
CoupledClutches_FMU1_CPP.mos

DEPENDENCIES = \
*.mo \
*.mos \
Makefile


CLEAN = `ls | grep -w -v -f deps.tmp`

.PHONY : test testAll clean getdeps failingtest

test:
	@echo
	@echo Running tests...
	@echo
	@echo OPENMODELICAHOME=" $(OPENMODELICAHOME) "
	@$(TEST) $(TESTFILES)

clean :
	@echo $(DEPENDENCIES) | sed 's/ /\\|/g' > deps.tmp
	@rm -rf $(CLEAN)
	@rm *_me_FMU.mo

getdeps:
	@echo $(DEPENDENCIES) | sed 's/ /\\|/g' > deps.tmp
	@echo $(CLEAN) | sed -r 's/deps.txt|deps.tmp//g' | sed 's/ / \\\n/g' > deps.txt
	@echo Dependency list saved in deps.txt.
	@echo Copy the list from deps.txt and add it to the Makefile @DEPENDENCIES

failingtest:
	@echo
	@echo Running failing tests...
	@echo
	@$(TEST) $(FAILINGTESTFILES)
