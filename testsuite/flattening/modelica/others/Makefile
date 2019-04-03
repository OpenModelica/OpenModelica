TEST=../../../rtest -v

TESTFILES=\
BoolArrayTest.mo \
BooleanDim.mo \
BooleanEnumDims.mo \
BooleanLiterals.mo \
BooleanRanges.mo \
CheckInstantiationLimit.mo \
Circuit1.mo \
Class1.mo \
Class2.mo \
Comment1.mo \
Comment2.mo \
ComponentNames.mo \
ComponentNames2.mo \
ComponentNamesRedecl.mo \
ConditionalComponent.mo \
CyclicBindingConditional.mo \
CyclicBindingConst.mo \
CyclicBindingParam.mo \
Derivative1.mo \
DiagonalBlock.mo \
DocString.mo \
DotOperator.mo \
DuplicateElements.mo \
DuplicateElementsNonEquivalent.mo \
DuplicateElementsExtends.mo \
DuplicateElementsExtendsEquivalent.mo \
Each1.mo \
End.mo \
EndIllegal.mo \
EndUnknown.mo \
ExtObjError.mo \
ExtObjError2.mo \
FaultNonPropagation.mo \
FlexibleShaftNonLinearTotal.mo \
FlowInvalid1.mo \
ForceAndTorque.mo \
ForIterator1.mo \
ForIterator2.mo \
ForIterator3.mo \
GetInstanceName.mo \
IconsRecursiveTest.mo \
if_then_elseif_else.mo \
IfExpCombiTable1.mo \
IfExpCombiTable2.mo \
IllegalSubscript.mo \
Influenza.mo \
InvertedPendulumTotal.mo \
ModelAccess.mo \
ModelSimple.mo \
NamedArguments.mo \
NestedClasses.mo \
NonfixedParamSubscript.mo \
NotDependsRecursive.mo \
OverrideFinalTest.mo \
Partial1.mo \
PDEModelicaTest.mos \
PEXPipeTotal.mo \
Philosopher2.mo \
Philosopher.mo \
Protected1.mo \
ProtectedAccess2.mo \
ProtectedAccess.mo \
prtest.mo \
PublicAccess.mo \
RecursiveDefinition.mo \
RecursiveShort.mo \
ReturnError.mo \
SampleError.mo \
Sequence.mo \
ShortClassDef.mo \
Simplify.mo \
Simplify2.mo \
SimplifyAbs.mo \
SimplifyBinary.mo \
SimplifyInteger1.mo \
SimplifyRangeInCall.mo \
SmallLinsys.mo \
Splice.mo \
SpliceUnknownDest.mo \
StringBoolean.mo \
StringConcatenation.mo \
StringConversion.mo \
StringInteger.mo \
StringLiterals.mo \
StringPool.mo \
StringReal.mo \
StructuralParameter1.mo \
SubScript1.mo \
SubScript2.mo \
SubScript3.mo \
SubscriptEval.mo \
Switch.mo \
ThermoPower.Examples.BraytonCycle.ClosedLoopSimulator.mos \
VectorizeExtendedType.mo \
WillowForest.mo \
Homotopy.mos

# test that currently fail. Move up when fixed. 
# Run make testfailing
FAILINGTESTFILES=\
ConstrainingType2.mo \
ConstrainingType3.mo \
ConstrainingType1.mo \
DuplicateElementsEquivalent.mo \


# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
*.mos \
Makefile \
CMakeLists.txt \
FlatParse.mof \
SmallPlantModified.mof \
VERSION.texi \
modtest.info \
modtest.texi 


CLEAN = `ls | grep -w -v -f deps.tmp`



DOCFILES=modtest.texi cases.texi VERSION.texi
DISTFILES=$(TESTFILES) VERSION modtest.texi \
	Makefile rtest cases.texi index.html
HTMLFILE=modtest_toc.html

TEXI2DVI=texi2dvi
TEXI2HTML=texi2html -split_chapter
MAKEINFO=makeinfo

VERSION = $(shell cat VERSION)

.PHONY : default
default : modtest.info modtest.ps $(HTMLFILE)

.PHONY : test failingtest clean getdeps

test :
	@echo
	@echo Running tests...
	@echo
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

keywords :
	$(TEST) -l $(TESTFILES)

modtest.dvi : $(DOCFILES)
	$(TEXI2DVI) $<

modtest.ps : modtest.dvi
	dvips -o $@ $<

modtest.info : $(DOCFILES)
	$(MAKEINFO) $<

$(HTMLFILE) : $(DOCFILES)
	$(TEXI2HTML) $<

cases.texi : $(TESTFILES)
	$(RM) $@
	cases=`$(TEST) -L $(TESTFILES) | sort`; \
	echo "@menu" >> $@; \
	for c in $$cases; do echo "* $$c::" >> $@; done; \
	echo "@end menu" >> $@; \
	set "Test Cases" $$cases ""; \
	while [ "$$2" != "" ] ; do \
		echo ""                 	    >> $@; \
		echo "@node $$2,$$3,$$1,Test Cases" >> $@; \
		echo "@appendixsec $$2" 	    >> $@; \
		echo "@example"         	    >> $@; \
		echo "@include $$2.mo"  	    >> $@; \
		echo "@end example"     	    >> $@; \
		shift ; \
	done

VERSION.texi : VERSION
	sed -e 's/^\(.*\)$$/@set VERSION \1/' < $< > $@

.PHONY : dist
dist : $(DISTFILES)
	mkdir modtest-$(VERSION)
	cp $(DISTFILES) modtest-$(VERSION)
	tar cvf modtest-$(VERSION).tar modtest-$(VERSION)
	gzip -9 modtest-$(VERSION).tar
	$(RM) -r modtest-$(VERSION)
