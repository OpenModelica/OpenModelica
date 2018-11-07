TEST = ../../../rtest -v

TESTFILES = \
VariableSubscriptAlias.mos \
ActivateWhenEquation.mos \
AliasEquations.mos \
BouncingBall.mos BouncingBall2.mos BouncingBallExamples.mos \
constantLinSys.mos \
Cross.mos \
DAEexample.mos DAEexample2.mos \
deriveToLog.mos \
DoubleWhenConflict.mos \
EqualityEquations.mos \
EqualityEquationsCorrect.mos \
FiveForEquations.mos \
FlatTank.mos \
HelloWorld.mos \
HideVariableForEquations.mos \
IfEquation.mos IfEquation2.mos IfEquation3.mos \
IfEquation4.mos \
IfEquation5.mos \
IfEquation6.mos \
IfEquationUnbalanced.mos \
ModelBalance1.mos ModelBalance2.mos ModelBalance3.mos ModelBalance4.mos \
ticket-2337.mos \
ticket-5206.mos \
WatchDog1AlgorithmWhen.mos WatchDog2EquationWhen.mos \
WhenEquation.mos WhenEquation1.mos \
WhenNoRetCall.mos \
when_sorting.mos \



# test that currently fail. Move up when fixed. 
# Run make testfailing
FAILINGTESTFILES= \
BouncingBallExamplesDOPRI5.mos \
WhenArrayReinit.mos \


# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
*.mos \
Makefile 


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
