TEST=../../../rtest -v

TESTFILES=\
Algorithm1.mo \
Algorithm2.mo \
Algorithm3.mo \
AlgorithmCondAssign1.mo \
AlgorithmCondAssign2.mo \
AlgorithmElseOpt.mo \
AlgorithmFor1.mo \
AlgorithmFor2.mo \
AlgorithmFor3.mo \
AlgorithmFor4.mo \
AlgorithmFor5.mo \
AlgorithmFor6.mo \
AlgorithmNoRetCall.mo \
AlgorithmSection.mo \
ArrayRange.mo \
AssignmentToInput.mo \
AssignmentErrorConstant.mo\
AssignmentErrorInput.mo \
AssignmentFunction.mo \
AssignmentFunctionMultiple1.mo \
AssignmentSimple.mo \
Break.mo \
ComponentFunctions.mo \
ElementWiseMultiplication.mo \
ErrorExternalAlgorithm.mo \
EvalUnknownDim.mo \
Faculty1.mo \
Faculty2.mo \
Faculty3.mo \
Faculty5.mo \
FilterBlock1.mo \
FlatTank.mo \
ForIteratorType.mo \
ForLoopHideVariable.mo \
ForNested.mo \
ForSimple.mo \
FuncDer.mo \
FuncMultResults.mo \
Function1.mo \
Function2.mo \
Function5.mo \
Function5_test.mo \
Function6.mo \
Function7.mo \
Function8.mo \
Function9.mo \
Function10.mo \
Function11.mo \
Function12.mo \
FunctionBreak.mo \
FunctionBubblesort.mo \
FunctionCall.mo \
FunctionDefaultArgs.mo \
FunctionDefaultArgs2.mo \
FunctionDefaultArgsCycle.mo \
FunctionDefaultArgsMod.mo \
FunctionEval1.mo \
FunctionEval2.mo \
FunctionEval3.mo \
FunctionEval4.mo \
FunctionEval6.mo \
FunctionEval7.mo \
FunctionEval8.mo \
FunctionEval9.mo \
FunctionEval10.mo \
FunctionEval11.mo \
FunctionEval12.mo \
FunctionEvalBuiltin.mo \
FunctionEvalFail.mo \
FunctionEvalSlice.mo \
FunctionInvalidVar1.mo \
FunctionInvalidVar2.mo \
FunctionInverse.mo \
FunctionMultiReturn.mo \
FunctionProtectedInput.mo \
FunctionReturn.mo \
FunctionSimple.mo \
FunctionSimplex.mo \
FunctionVariability.mo \
FunctionWithEquation.mo \
IfExpression1.mo \
InvalidFunctionBinding.mo \
JoinThreeVectors2.mo \
LeastSquares.mo \
LogCall1.mo \
modelica_1_1_Function10.mo \
MRFcall.mo \
MultFuncCall.mo \
PrefixPartialFunctionApplication.mo \
RecursiveCallExtends.mo \
RecursiveFunctionCall.mo \
StackOverflowTest.mos \
Summation.mo \
SumSeriesWhile.mo \
SumVectorForIf.mo \
TestGravityAcceleration.mo \
Ticket4365.mos \
Ticket4786.mo \
Ticket4838.mo \
TupleError.mo \
TupleSingleAssign.mo \
TupleAssignmentMismatch1.mo \
tupleSubset.mo \
UnusedInput.mo \
UnknownDimensionFunctionCall.mo \
Vectorizable1.mo \
Vectorizable3.mo \
Vectorizable5.mo \
Vectorizable6.mo \
Vectorizable7.mo \
WhenElseNested.mo \
WhenNested.mo \
WhenPriority.mo \
WhenStatement1.mo \
WhenStatement2.mo \
WhenStatement3.mo \
While.mo

# test that currently fail. Move up when fixed.
# Run make testfailing
FAILINGTESTFILES=\
AssignmentFunctionMultiple2.mo \
Faculty4.mo \
Function4.mo \
FunctionEval5.mo \
Inline1.mo \
Inline2.mo \
Inline3.mo \
Inline4.mo \
Inline5.mo \
Inline6.mo \
OutOfMemory.mos \
StatementCall.mo \
Vectorizable2.mo

# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
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
