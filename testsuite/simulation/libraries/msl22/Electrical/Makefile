TEST = ../../../../rtest -v

TESTFILES = \
CauerLowPassOPV2.mos \
ChuaCircuit2.mos \
HeatingMOSInverter2.mos \
ShowVariableResistor2.mos \

# test that currently fail. Move up when fixed. 
# Run make testfailing
FAILINGTESTFILES=  \
CharacteristicThyristors2.mos \
HeatingNPN_OrGate2.mos \
HeatingResistor.mos \
OvervoltageProtection2.mos \
Rectifier2.mos \
ShowSaturatingInductor2.mos \
SwitchWithArc2.mos \
ThyristorBehaviourTest2.mos \
CauerLowPassSC2.mos \
HeatingRectifier2.mos


# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
*.mos \
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
