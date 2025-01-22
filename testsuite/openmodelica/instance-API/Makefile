TEST = ../../rtest -v

TESTFILES = \
GetModelInstanceAlgorithm1.mos \
GetModelInstanceAnnotation1.mos \
GetModelInstanceAnnotation2.mos \
GetModelInstanceAnnotation3.mos \
GetModelInstanceAnnotation4.mos \
GetModelInstanceAnnotation5.mos \
GetModelInstanceAnnotation6.mos \
GetModelInstanceAnnotation7.mos \
GetModelInstanceAnnotation8.mos \
GetModelInstanceAnnotation9.mos \
GetModelInstanceAnnotation10.mos \
GetModelInstanceAnnotation11.mos \
GetModelInstanceAnnotation12.mos \
GetModelInstanceAnnotation13.mos \
GetModelInstanceAnnotation14.mos \
GetModelInstanceAttributes1.mos \
GetModelInstanceAttributes2.mos \
GetModelInstanceBinding1.mos \
GetModelInstanceBinding2.mos \
GetModelInstanceBinding3.mos \
GetModelInstanceBinding4.mos \
GetModelInstanceBinding5.mos \
GetModelInstanceBinding6.mos \
GetModelInstanceBinding7.mos \
GetModelInstanceBinding8.mos \
GetModelInstanceBinding9.mos \
GetModelInstanceBinding10.mos \
GetModelInstanceBreak1.mos \
GetModelInstanceChoices1.mos \
GetModelInstanceChoices2.mos \
GetModelInstanceComment1.mos \
GetModelInstanceConditional1.mos \
GetModelInstanceConditional2.mos \
GetModelInstanceConnection1.mos \
GetModelInstanceConnection2.mos \
GetModelInstanceConnection3.mos \
GetModelInstanceConnection4.mos \
GetModelInstanceConnection5.mos \
GetModelInstanceConnection6.mos \
GetModelInstanceDerived1.mos \
GetModelInstanceDerived2.mos \
GetModelInstanceDerived3.mos \
GetModelInstanceDim1.mos \
GetModelInstanceDim2.mos \
GetModelInstanceDim3.mos \
GetModelInstanceDuplicate1.mos \
GetModelInstanceEnum1.mos \
GetModelInstanceEnum2.mos \
GetModelInstanceEvaluate1.mos \
GetModelInstanceExp1.mos \
GetModelInstanceExp2.mos \
GetModelInstanceExtends1.mos \
GetModelInstanceExtends2.mos \
GetModelInstanceExtends3.mos \
GetModelInstanceFunction1.mos \
GetModelInstanceIcon1.mos \
GetModelInstanceIcon2.mos \
GetModelInstanceIcon3.mos \
GetModelInstanceIcon4.mos \
GetModelInstanceImport1.mos \
GetModelInstanceImport2.mos \
GetModelInstanceInnerOuter1.mos \
GetModelInstanceInnerOuter2.mos \
GetModelInstanceInnerOuter3.mos \
GetModelInstanceInnerOuter4.mos \
GetModelInstanceInnerOuter5.mos \
GetModelInstanceMissingClass1.mos \
GetModelInstanceMissingClass2.mos \
GetModelInstanceMissingClass3.mos \
GetModelInstanceMod1.mos \
GetModelInstanceMod2.mos \
GetModelInstanceMod3.mos \
GetModelInstanceMod4.mos \
GetModelInstanceMod5.mos \
GetModelInstanceMod6.mos \
GetModelInstanceProtected1.mos \
GetModelInstanceReplaceable1.mos \
GetModelInstanceReplaceable2.mos \
GetModelInstanceReplaceable3.mos \
GetModelInstanceReplaceable4.mos \
GetModelInstanceReplaceable5.mos \
GetModelInstanceReplaceable6.mos \
GetModelInstanceReplaceableComment.mos \
GetModelInstanceStateMachine1.mos \
ModifierToJSON1.mos \
QualifyPath1.mos \


# test that currently fail. Move up when fixed.
# Run make testfailing
FAILINGTESTFILES=

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
