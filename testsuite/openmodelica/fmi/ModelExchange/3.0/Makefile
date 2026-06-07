TEST = ../../../../rtest -v

TESTFILES = \
fmi3_attributes_01.mos \
fmi3_arrays.mos \
fmi3_types.mos \
fmi3_terminals.mos \
fmi3_binary_extobj.mos \
fmi3_fmustate.mos \
fmi3_directional_derivatives.mos \
fmi3_builddescription.mos \
fmi3_clocks.mos \
fmi3_graphics.mos

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
	@rm -f $(CLEAN)

# Run this if you want to list out the files (dependencies).
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
