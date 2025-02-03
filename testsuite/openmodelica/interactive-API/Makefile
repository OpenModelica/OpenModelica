TEST = ../../rtest -v

TESTFILES = \
AddClassAnnotation.mos \
addComponent1.mos \
addComponent2.mos \
addConnection1.mos \
ArraySlicing.mos \
Bug2871.mos \
Bug2882.mos \
Bug2943.mos \
Bug3269_deleteFile.mos \
Bug3282.mos \
Bug3417.mos \
Bug3520.mos \
Bug3783.mos \
Bug3974.mos \
Bug3979.mos \
Bug4248.mos \
Buildings.PartialFlowMachine.mos \
checkAllModelsRecursive1.mos \
CheckModelExtObj1.mos \
choicesAllMatching.mos \
ConnectionList.mos \
ConversionVersions.mos \
ConvertUnits.mos \
CopyClass.mos \
CopyClass1.mos \
CopyClass2.mos \
CopyClass3.mos \
CopyClass4.mos \
CopyClass5.mos \
CopyClass6.mos \
CopyClassInvalid1.mos \
CopyClassRedeclare1.mos \
DefaultComponentName.mos \
DeleteConnection.mos \
DialogAnnotation.mos \
FlagParsing.mos \
ForStatement1.mos \
ForStatement2.mos \
ForStatement3.mos \
ForStatement4.mos \
ForStatement5fail.mos \
ForStatement6.mos \
ForStatement7.mos \
ForStatement8.mos \
GetAllSubtypeOf1.mos \
GetAllSubtypeOf2.mos \
GetAllSubtypeOf3.mos \
getClassComment.mos \
getClassNames.mos \
getCommandLineOptions.mos \
GetComponents.mos \
getComponentsTestNF.mos \
getComponentsTestOF.mos \
getConnectorCount.mos \
getDefinitions.mos \
getDialogAnnotation.mos \
getElementAnnotation.mos \
getElements1.mos \
getExtendsModifierNames.mos \
getIconAnnotation.mos \
getInheritedClasses1.mos \
getInheritedClasses2.mos \
getNthComponentAnnotation.mos \
getNthConnector.mos \
getNthConnectorIconAnnotation.mos \
getSimulationOptions1.mos \
getSimulationOptions2.mos \
getSimulationOptions3.mos \
IfStatementIllegal.mos \
IfStatement.mos\
IllegalGraphics.mos\
instantiateFunction.mos \
interactive_api_annotations.mos \
interactive_api_attributes.mos \
interactive_api_calls.mos \
interactive_api_classes.mos \
interactive_api_loadsave.mos \
interactive_api_param.mos \
interactive_api_simulations.mos \
interactive_test.mos \
isConstant.mos \
isExperiment.mos \
isParameter.mos \
isPrimitive.mos \
isProtected.mos \
isRedeclare.mos \
isReplaceable.mos \
Issue7544.mos \
Issue7706.mos \
ListAnnotation.mos \
ListExpressions.mos \
ListImport.mos \
ListMultilineComment.mos \
loadClassContentString1.mos \
loadClassContentString2.mos \
loadFileInteractiveQualified.mos \
matrices.mos \
Modelica.Media.Examples.getComponents.mos \
MoveClass2.mos \
MoveClass.mos \
ModelicaError.mos \
Obfuscation1.mos \
Obfuscation2.mos \
Obfuscation3.mos \
Obfuscation4.mos \
Obfuscation5.mos \
ProtectedHandlingBug2917.mos \
ReadOnlyPkg.mos \
readSimulationResult1.mos \
refactorGraphAnn1.mos \
refactorGraphAnn2.mos \
regex.mos \
Rename.mos \
RunScript.mos \
saveShort.mos \
saveTotalModel.mos \
setComponentComment.mos \
setComponentModifierValue.mos \
setElementAnnotation.mos \
setElementType.mos \
setElementModifierValue.mos \
setExtendsModifierValue.mos \
setExtendsModifier.mos \
setParameterValue.mos \
setSourceFileListFile.mos \
showDoc.mos \
showStructuralAnnotations.mos \
StateMachine.mos \
StoreAST.mos \
strings.mos  \
stringSplit.mos \
TestChoices.mos \
Ticket4674.mos \
Ticket5506.mos \
Ticket5548.mos \
Ticket5565.mos \
Ticket5571.mos \
Ticket5662.mos \
Ticket5680.mos \
Ticket5696.mos \
Ticket5871.mos \
Ticket6167.mos \
Ticket6287and6288.mos \
Ticket6300.mos \
Ticket6307.mos \
Ticket6406.mos \
UsesAnnotation1.mos \
UsesAnnotation2.mos \
variables.mos \
VendorAnnotation.mos \
TestSpace.mos \


# test that currently fail. Move up when fixed.
# Run make testfailing
FAILINGTESTFILES=differentiate.mos

# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
*.mos \
ReadOnlyPkg \
TestDirPkg \
TestTicket5871 \
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
