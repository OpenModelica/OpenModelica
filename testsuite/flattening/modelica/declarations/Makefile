TEST=../../../rtest -v

TESTFILES=\
Annotations.mo \
BuiltinTime1.mo \
BuiltinTimeInvalid1.mo \
BuiltinTimeInvalid2.mo \
CondDeclaration.mo \
Constant1.mo \
Constant2.mo \
Constant3.mo \
Constant4.mo \
Constant5.mo \
Constant6.mo \
Constant7.mo \
Constant8.mo \
Constant9.mo \
Constant10.mo \
Constant11.mo \
Constant12.mo \
Constant13.mo \
ConstantDeclConnector.mo \
ConstantDeclRecord.mo \
ConstantDeclType.mo \
ConstantReductions.mo \
ConstructParameters.mo \
ConstructParameters2.mo \
DeclarationEquation1.mo \
DeclarationEquation2.mo \
DeclarationEquation3.mo \
DeclarationOrder.mo \
DeclarationOrder1.mo \
DeclarationOrder2.mo \
DeclareConstant3.mo \
Discrete1.mo \
DiscreteDeclConnector.mo \
DiscreteDeclRecord.mo \
DiscreteDeclType.mo \
DoubleDeclaration.mo \
DoubleClassDeclaration1.mo \
DoubleClassDeclaration2.mo \
DoubleFuncDeclaration.mo \
ErrorExternalModel.mo\
ErrorRecursionLimit.mo \
FloatingPoint.mo \
FlowDeclConnector.mo \
FlowDeclRecord.mo \
FlowDeclRecord2.mo \
FlowDeclType.mo \
InputDeclConnector.mo \
InputDeclRecord.mo \
InputDeclType.mo \
LhsIf.mo \
MultipleDeclarations.mo \
MyPointsInst1.mo \
MyPointsInst2.mo \
OutputDeclConnector.mo \
OutputDeclRecord.mo \
OutputDeclType.mo \
ParameterDeclConnector.mo \
ParameterDeclRecord.mo \
ParameterDeclType.mo \
ScalarizeBindings.mo \
SimpleIntegrator1.mo \
SimpleIntegrator2.mo \
SimpleIntegrator3.mo \
ScopeDeclaration1.mo \
ScopeDeclaration2.mo \
ScopeDeclaration3.mo \
ScopeModification1.mo \
ScopeModification2.mo \
TestPackageConstantHandling.mo \
Ticket4276a.mo \
Ticket4276b.mo \


# test that currently fail. Move up when fixed. 
# Run make testfailing
FAILINGTESTFILES=\
DeclareConstant1.mo \
DeclareConstant2.mo \
Discrete2.mo \
ErrorMultipleClasses.mo \
MultipleDeclarations2.mo \
ScopeDeclaration4.mo 


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
