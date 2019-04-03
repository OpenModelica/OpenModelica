TEST = ../../../rtest -v

#Files to create _prof.xml
PROFFILES = \
BouncingBall_prof.mos \
ElectricalCircuit_prof.mos \
Modelica.Electrical.Spice3.Examples.CoupledInductors_prof.mos \
simpleResistor_prof.mos \
Modelica.Mechanics.MultiBody.Examples.Loops.EngineV6_prof.mos
			
# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
*.mos \
Makefile


# PROFDEPENDENCIES = \
# *_prof.xml


CLEAN = `ls | grep -w -v -f deps.tmp`
# CLEANPROF = `ls | grep -w -v -f depsprof.tmp`

.PHONY : profiling clean getdeps failingtest

profiling:
	@echo
	@echo Creating profiling files...
	@echo
	@echo OPENMODELICAHOME=" $(OPENMODELICAHOME) "
	@$(foreach file,$(PROFFILES),omc $(file);)
	mv *_prof.xml ../
	
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
