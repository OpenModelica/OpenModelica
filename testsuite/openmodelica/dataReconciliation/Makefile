TEST = ../../rtest -v
BASELINE = ../../rtest -b

TESTFILES = \
DistillationTower.mos\
VDI2048Exple.mos\
Pipe1.mos\
Pipe2.mos\
Pipe3.mos\
Pipe4.mos\
Pipe5.mos\
Pipe6.mos\
Splitter.mos\
Splitter1.mos\
Splitter2.mos\
Splitter3.mos\
Splitter4.mos\
Splitter5c.mos\
Splitter5d.mos\
Splitter5e.mos\
Splitter5f.mos\
Splitter5g.mos\
Splitter5h.mos\
stateEstimation.mos\
stateEstimation2.mos\
FourFlows.mos\
TSP_Pipe.mos\
TSP_Pipe1.mos\
TSP_Pipe2.mos\
TSP_Pipe4.mos\
TSP_Pipe7.mos\
TSP_Pipe8.mos\
TSP_Pipe9.mos\
TSP_Pipe10.mos\
TSP_Pipe11.mos\
TSP_Splitter1.mos\
TSP_Splitter2.mos\
TSP_Splitter3.mos\
TSP_Splitter4.mos\
TSP_Splitter5.mos\
TSP_Splitter6.mos\
TSP_Splitter7.mos\
TSP_FourFlows.mos\
TSP_FourFlows1.mos\
TSP_FourFlows3.mos\
TSP_FourFlows8.mos\

# test that currently fail. Move up when fixed.
# Run make testfailing
FAILINGTESTFILES= \
TSP_FourFlows2.mos\
TSP_FourFlows4.mos\
TSP_FourFlows5.mos\
TSP_FourFlows6.mos\
TSP_FourFlows7.mos\
TSP_FourFlows9.mos\
TSP_FourFlows11.mos\
TSP_Pipe6.mos\
TSP_Pipe5.mos\
TSP_FourFlows10.mos\
TSP_Pipe3.mos\


# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
*.mos \
*.csv  \
*.txt   \
*.html   \
Makefile


CLEAN = `ls | grep -w -v -f deps.tmp`

.PHONY : test clean getdeps failingtest

test:
	@echo
	@echo Running tests...
	@echo
	@echo OPENMODELICAHOME=" $(OPENMODELICAHOME) "
	@$(TEST) $(TESTFILES)

baseline:
	@echo
	@echo Running baseline for tests...
	@echo
	@echo OPENMODELICAHOME=" $(OPENMODELICAHOME) "
	@$(BASELINE) $(TESTFILES)

failtestbaseline:
	@echo
	@echo Running baseline for failing tests...
	@echo
	@echo OPENMODELICAHOME=" $(OPENMODELICAHOME) "
	@$(BASELINE) $(FAILINGTESTFILES)

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
