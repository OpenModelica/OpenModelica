TEST = ../../../../rtest -v


TESTFILES = \
BR.mos \
BReqcon.mos \
BRinitialGuess.mos\
BRcon.mos \
BRcon2.mos \
BRcon3.mos \
BRcon4.mos \
BRcon5.mos \
BRscale.mos \
CC.mos \
CM.mos \
CM2.mos \
DM.mos \
DMwarm.mos \
DMwarmCsv.mos \
LoopTest.mos \
LRB.mos \
LRB2.mos \
LV.mos \
NP.mos \
noOCP.mos \
ocpWithInputs.mos \
OSP.mos \
OSP2.mos \
pendel.mos \
reduce1.mos \
SC.mos \
staticOP.mos \
VDP.mos \
VDPchekError.mos \
TestConstraintsAlias.mos \
testDerInput.mos \
testAlgLoop1.mos \
testAlgLoop2.mos \
testAlgLoop3.mos \
testAlgLoop4.mos \
testAlgLoop5.mos \
testAlgLoop6.mos \
testAlgLoop7.mos \
testAlgLoop8.mos \
testAlgLoop9.mos \
testAlgLoop10.mos \
testAlgLoop11.mos \
testSimpliCon1.mos \
TFC.mos \
TFC2.mos \
TFC3.mos \
TFC4.mos \
TFC5.mos \
TFC6.mos \
TFC7.mos \
TFC8.mos \
TFCtestFlag.mos \
TT.mos \


# test that currently fail. Move up when fixed. 
# Run make testfailing
FAILINGTESTFILES = \
TT2.mos \
TT3.mos \


# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
*.mos \
Makefile \
ReferenceFiles


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
