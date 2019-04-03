TEST=../../../rtest -v

TESTFILES=\
ActivateWhenEquation.mo \
BouncingBall.mo \
Bug4124.mos \
Circle.mo \
ConditionalArrayExpression1.mo \
ConditionalArrayExpression2.mo \
ConnectInNonParamIf.mo \
ConnectInWhen.mo \
DAEexample.mo \
EnumEquation1.mo \
Epidemics1.mo \
EqualityEquations.mo \
EqualityEquationsCorrect.mo \
EquationCall.mo \
EquationComponent1.mo \
EquationComponent2.mo \
EquationComponent3.mo \
EquationComponent4.mo \
EquationComponent5.mo \
EquationFor1.mo \
EquationFor2.mo \
EquationFor3.mo \
EquationFor4.mo \
EquationFor5.mo \
EquationFor6.mo \
EquationFor7.mo \
EquationIf1.mo \
EquationIf2.mo \
EquationIf3.mo \
EquationIf4.mo \
Equations.mo \
FiveForEquations.mo \
ForIf.mo \
HelloWorld.mo\
HideVariableForEquations.mo \
HydrogenIodide.mo \
IfEquation.mo \
InitialReduction.mo \
InOutBool.mo \
LotkaVolterra.mo \
ModifiedFiltersInSeries.mo \
SimplePeriodicSampler.mo \
Ticket4157.mos \
TwoRateSampler.mo \
VanDerPol.mo \
VariableRange.mo \
WatchDog1AlgorithmWhen.mo \
WatchDog2EquationWhen.mo \
WaveEquationSample.mo \
WhenEquation.mo \
WhenNestedEquation.mo \
WhenNotInitial.mo \
WhenNotValid.mo \
WhenValidResult.mo \
WhenSemantics1.mo \
WhenVectorPredicateEquation.mo \
WhenWithArray.mo



# test that currently fail. Move up when fixed. 
# Run make testfailing
FAILINGTESTFILES=\



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
