TEST = ../../../../rtest -v

TESTFILES = \
Aufgabe1_1.mos \
Aufgabe1_2.mos \
Aufgabe2.Test1.mos \
Aufgabe2.Test2.mos \
ServoSystem1.Aufgabe3_2.mos \
ServoSystem1.Aufgabe3_3.mos \
ServoSystem3.Aufgabe3_2.mos \
ServoSystem3.Aufgabe3_3.mos \
ServoSystem3.Aufgabe4_1.mos \
ServoSystem3.Aufgabe4_2.mos \
ServoSystem3.Aufgabe4_3a.mos \
ServoSystem3.Aufgabe4_3b.mos \
ServoSystem3.Aufgabe4_4a.mos \
FourBar.TestPlanarLoops.mos \


# test that currently fail. Move up when fixed. 
# Run make testfailing
FAILINGTESTFILES= \
ServoSystem3.Aufgabe4_4b.mos \


# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
1 \
2 \
3 \
4 \
5 \
*.mo \
*.mos \
README.txt \
Makefile 

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

failingtest:
	@echo RTEST_OMCFLAGS = $(RTEST_OMCFLAGS)
	@echo
	@echo Running failing tests...
	@echo
	@$(TEST) $(FAILINGTESTFILES)

