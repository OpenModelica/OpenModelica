TEST = ../../rtest -v

TESTFILES = \
lateInline.mos \
optdaedump.mos \
optSimpleSolveDAEdump.mos \
paramdlowdump.mos \
symjacdump.mos \
tearingdump.mos \
libraryCoverageFlags.mos \


FAILINGTESTFILES = \
dumpSparsePattern.mos \
dumpSparsePatternVerbose.mos \
symjacdumpverbose.mos \
backenddaeinfo.mos \
bltdump.mos \
daedumpgraphv.mos \
daeunparser.mos \
dumpConstrepl.mos \
dumpdaelow.mos \
dumpderrepl.mos \
dumpEArepl.mos \
dumpEncapsulateConditions.mos \
dumpeqninorder.mos \
dumpFPrepl.mos \
dumpindxdae.mos \
dumpinitialsystem.mos \
dumpInlineSolver.mos \
dump.mos \
dumpoptinit.mos \
dumpParamrepl.mos \
dumpPPrepl.mos \
dumprepl.mos \
dumpTransformedModelica.mos \
interactivedump.mos \
semiLinear.mos \
showEquationSource.mos \
showStartOrigin.mos \
stateselection.mos \
symjacdumpeqn.mos \
transformsbeforedump.mos \
uncertainties.mos \


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
