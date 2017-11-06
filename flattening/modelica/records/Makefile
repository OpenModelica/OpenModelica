TEST = ../../../rtest -v

TESTFILES = \
 ComplexBinding1.mo \
 DefaultRecordParameters.mo \
 Derived1.mo \
 Derived2.mo \
 EmptyRecordTestConstructor.mos \
 EmptyRecordTestInput.mos \
 EngineSAAB95Total.mo \
 IntegerRealCast.mo \
 NestedRecordTestConstructor.mos  \
 NestedRecordTestInput.mos \
 OperatorOverloadComplexArray.mo \
 OperatorOverloadComplex.mo \
 Record1.mo \
 RecordAssignment.mo \
 RecordBindingsOrdered.mo \
 RecordClassModOutput.mo \
 RecordConnections.mo \
 RecordConstant1.mo \
 RecordConstant2.mo \
 RecordConstant3.mo \
 RecordConstant4.mo \
 RecordConstructors2.mo \
 RecordConstructors.mo \
 RecordConstructorVectorization.mo \
 RecordDefaultArg.mo \
 RecordDefaultArgMod.mo \
 RecordEnumBinding.mo \
 RecordEquationSize.mos \
 RecordFuncParam.mo \
 RecordFuncParam.mos \
 RecordModifications2.mo \
 RecordNonPublic.mo \
 RecordParameters.mos \
 RecordSimple.mo \
 RecordSliceAssign.mo \
 RecordVariability.mo \
 SimpleRecordTestConstructor.mos \
 SimpleRecordTestInput.mos \

# test that currently fail. Move up when fixed. 
FAILINGTESTFILES= \
RecordModifications.mo \
RecordPrefixes.mo \

# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
 *.mo \
 *.mos \
 Makefile \
 External_C_RecordTest.c  

CLEAN = `ls | grep -w -v -f deps.tmp`

.PHONY : test clean getdeps

test :
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
