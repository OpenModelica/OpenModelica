# 
TEST = ../../../rtest

TESTFILES = \
ExpandableConnector1.mo \
ExpandableConnector2.mo \
ExpandableConnector3.mo \
ExpandableConnector4.mo \
ExpandableConnector5.mo \
ExpandableConnector6.mo \
ExpandableConnector7.mo \
ExpandableConnector8.mo \
ExpandableConnector9.mo \
ExpandableConnector10.mo \
ExpandableConnector11.mo \
ExpandableConnector12.mo \
ExpandableConnector13.mo \
ExpandableConnectorArray1.mo \
ExpandableConnectorArray2.mo \
ExpandableConnectorArray3.mo \
ExpandableConnectorArray4.mo \
ExpandableConnectorComplex1.mo \
ExpandableConnectorFlow1.mo \
ExpandableConnectorFlow2.mo \
ExpandableConnectorHierarchy1.mo \
ExpandableConnectorHierarchy2.mo \
ExpandableConnectorNonDecl1.mo \
ExpandableConnectorNonDecl2.mo \
ExpandableConnectorNonDecl3.mo \
ExpandableConnectorNonDecl4.mo \
ExpandableConnectorPresent1.mo \
ExpandableConnectorPresent2.mo \
InvalidExpandableConnector1.mo \
QHP_Electrolytes_test_T2.mos \

# test that currently fail. Move up when fixed. 
# Run make testfailing
FAILINGTESTFILES = \
ExpandableConnectorArray5.mo \
ExpandableConnectorArray6.mo \
ExpandableConnectorHierarchy3.mo \
ExpandableVariableUsed.mo \

# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
*.mos \
Makefile 


CLEAN = `ls | grep -w -v -f deps.tmp`

.PHONY : test clean getdeps failingtest

test :
	@echo
	@echo Running tests:
	@echo
	@$(TEST) $(TESTFILES)
	
# Cleans all files that are not listed as dependencies 
clean :
	@echo $(DEPENDENCIES) | sed 's/ /\\|/g' > deps.tmp
	@rm -f $(CLEAN)

# Get the dependency files
getdeps: 
	@echo $(DEPENDENCIES) | sed 's/ /\\|/g' > deps.tmp
	@echo $(CLEAN) | sed -r 's/deps.txt|deps.tmp//g' | sed 's/ / \\\n/g' > deps.txt	
	@echo Dependency list saved in deps.txt.
	@echo Copy the list from deps.txt and add it to the Makefile @DEPENDENCIES
	
failingtest :
	@echo
	@echo Running failing tests...
	@echo
	@$(TEST) -disabled $(FAILINGTESTFILES)
