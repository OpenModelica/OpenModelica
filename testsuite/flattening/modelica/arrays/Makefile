TEST=../../../rtest -v

TESTFILES=\
ABCDsystem.mo \
AdvancedDimensions.mo \
AppendElement.mo \
Array10.mo \
Array11.mo \
Array12.mo \
Array13.mo \
Array14.mo \
Array15.mo \
Array1.mo \
Array2.mo \
Array3.mo\
Array4.mo \
Array7.mo \
Array8.mo \
Array9.mo \
ArrayAccess.mo \
ArrayAddEmpty.mo \
ArrayAddition2.mo \
ArrayAddition.mo \
ArrayAddSub1.mo \
ArrayAddSub.mo \
ArrayAsAliasInExtends.mo \
ArrayAsAlias.mo \
ArrayAssignEmpty.mo \
ArrayAssignWholeDim.mo \
ArrayBrackets.mo \
Array_builtin.mo \
ArrayCall.mo \
ArrayConstruct1.mo \
ArrayCurlyBrackets.mo \
ArrayDeclaration1.mo \
ArrayDeclaration2.mo \
ArrayDeclaration3.mo \
ArrayDeclaration4.mo \
ArrayDeclaration5.mo \
ArrayDim1.mo \
ArrayDim2.mo \
ArrayDim3.mo \
ArrayDim4.mo \
ArrayDivError.mo \
ArrayDivision.mo \
ArrayDiv.mo \
ArrayEWOps1.mo \
ArrayEWOps2.mo \
ArrayEWOps3.mo \
ArrayEWOps4.mo \
ArrayEWOps5.mo \
ArrayEWOps6.mo \
ArrayEWOpsCEval1.mo \
ArrayEWOpsCEval2.mo \
ArrayEWOpsCEval3.mo \
ArrayEWOpsCEval4.mo \
ArrayEWOpsCEval5.mo \
ArrayExponentiation.mo \
ArrayExtend.mo \
ArrayExtendsUnknown.mo \
ArrayIndex2.mo \
ArrayIndex3.mo \
ArrayIndex.mo \
ArrayInvalidDims.mo \
ArrayLogic.mo \
ArrayMatrixMatrixMul1.mo \
ArrayMatrixMatrixMul2.mo \
ArrayMatrixMatrixMul3.mo \
ArrayMatrixMatrixMul4.mo \
ArrayMatrixMatrixMul5.mo \
ArrayMatrixMatrixMul6.mo \
ArrayMatrixSimplifier.mo \
ArrayMatrixVectorMul1.mo \
ArrayMatrixVectorMul2.mo \
ArrayMatrixVectorMul3.mo \
ArrayMatrixVectorMul4.mo \
ArrayMatrixVectorMul5.mo \
ArrayModification1.mo \
ArrayModification2.mo \
ArrayMulMatrixSimplifier.mo \
ArrayMultiplication.mo \
ArrayMult.mo \
ArrayOperators.mo \
ArrayOuterParamExpand.mo \
ArrayRange.mo \
ArrayRecursiveDim1.mo \
ArrayReduce2.mo \
ArrayReduce.mo \
ArrayRemoveIndex1.mo \
ArraysInitLegal.mo \
ArraySizeFromFunc.mo \
ArraySlice1.mo \
ArraySlice2.mo \
ArraySubtraction.mo \
ArrayTuple.mo \
ArrayVectorMatrixMul1.mo \
ArrayVectorMatrixMul2.mo \
ArrayVectorMatrixMul3.mo \
ArrayVectorMatrixMul4.mo \
ArrayVectorMatrixMul5.mo \
ArrayVectorVectorMul1.mo \
ArrayVectorVectorMul2.mo \
ArrayVectorVectorMul3.mo \
ArrayVectorVectorMul4.mo \
BadVariabilityBug3150.mo \
BlockMatrix2.mo \
BlockMatrix3.mo \
BlockMatrix.mo \
BooleanArrayEq.mo \
Concat3.mo \
ConstructFunc.mo \
DiscreteVectorStateSpace.mo \
DoubleWhenSequential.mo \
EmptyArrayAlgorithm.mo \
EmptyArray.mo \
EmptyArraySubscript.mo \
EmptyAsubSliceSubscript.mo \
FillSubscriptsTest.mo \
FixedFinalParameter.mo \
InOutArray2.mo \
InOutArray.mo \
Matrix.mo \
Matrix1.mo \
Matrix2.mo \
Matrix3.mo \
MatrixAddition.mo \
MatrixBrackets.mo \
MatrixEquation.mo \
MatrixImplCast.mo \
MatrixMulVector.mo \
MatrixPow.mo \
MatrixRowIndexing.mo \
MatrixSubtraction.mo \
modelica_1_1_Array9.mo \
NestedSubscriptFor.mo \
PolynomialEvaluator1.mo \
PolynomialEvaluator2.mo \
PolynomialEvaluator3.mo \
PolynomialEvaluatorA.mo \
PolynomialEvaluatorB.mo \
QualifiedEnd.mo \
QualifiedSlicing.mo \
Range1.mo \
Range2.mo \
RangeSlicing.mo \
RangeVector.mo \
SliceMultiplication.mo \
SubscriptsFill1.mo \
TestArrayUnknown.mo \
TestFill.mo \
TypeTest.mos \
UnknownDimensionMod.mo \
VectorizeConstCref2D.mo \
VectorizeOneReturnValue.mo \
VectorizeSeveralArguments.mo \
WrongNumberOfSubscripts1.mo \
XPowers1.mo \
XPowers2.mo \
XPowers3.mo \

# test that currently fail. Move up when fixed. 
# Run make testfailing
FAILINGTESTFILES=\
Array5.mo \
Array6.mo \
ArraySlice.mo \
ArrayAlgebraFunc.mo \
ArrayEmpty.mo \
ConcatArr1.mo \
ConcatArr2.mo \
ConcatArr4.mo \
DimConvert.mo \
DimSize.mo \
DoubleWhenConflict.mo \
ErrorUnknownDimension.mo \
IndexOutOfBoundsConnect1.mo \
IndexOutOfBoundsConnect2.mo \
IndexOutOfBoundsConnect3.mo \
IndexOutOfBoundsConnect4.mo \
NonExpArray1.mo \
NonExpArray2.mo \
NonExpArray3.mo \
NonExpArray4.mo \
NonExpModif1.mo \
NonExpModif2.mo \
PointInst.mo \
SubArrayIndex.mo  \
VectorizeSumVec.mo \
WrongSubscriptType1.mo \

# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
*.mos \
Makefile 

CLEAN = `ls | grep -w -v -f deps.tmp`

DOCFILES=modtest.texi cases.texi VERSION.texi
DISTFILES=$(TESTFILES) VERSION modtest.texi \
	Makefile rtest cases.texi index.html
HTMLFILE=modtest_toc.html

TEXI2DVI=texi2dvi
TEXI2HTML=texi2html -split_chapte
MAKEINFO=makeinfo

VERSION = $(shell cat VERSION)

.PHONY : default
default : modtest.info modtest.ps $(HTMLFILE)

.PHONY : test failingtest clean getdeps
test :
	@echo
	@echo Running tests:
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
	@echo Running failing tests:
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
