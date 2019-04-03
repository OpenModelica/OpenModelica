TEST=../../../rtest -v

TESTFILES=\
AttributesPropagation.mo \
Bug2695.mo \
Bug2727.mo \
Bug2784.mo \
Bug3239.mo \
ClassExtends1.mo \
ClassExtends2.mo \
ClassExtends3.mo \
ClassExtends4.mo \
ClassExtends5.mo \
ClassExtends6.mo \
ClassExtendsInvalid2.mo \
ComparePSD.mo \
ConstrainedByMods.mo \
ConstantRedeclareModifier.mo \
Dependency.mos \
DuplicateRedeclares1.mo \
DuplicateRedeclares2.mo \
ExtendsDerived.mo \
FinalRedeclareModifier.mo \
FinalRedeclareModifier2.mo \
IgnoreReplaceable.mo \
ModifiersPriority.mo \
NonexistentElementRedeclare1.mo \
NonexistentElementRedeclare2.mo \
RDCL.mo \
Redeclare1.mo \
Redeclare2.mo \
Redeclare3.mo \
Redeclare4.mo \
Redeclare5.mo \
Redeclare6.mo \
Redeclare6.mos \
RedeclareArrayComponent1.mo \
RedeclareBaseClass1.mo \
RedeclareClass1.mo \
RedeclareClass4.mo \
RedeclareElementCondition.mo \
RedeclareFlowEffort.mo \
RedeclareFunction.mo \
RedeclareFunction1.mo \
RedeclareFunctionSameType.mo \
RedeclareInClassModification.mo \
RedeclareLocalClass.mo \
RedeclareModifierInvalid1.mo \
RedeclareModifierInvalid2.mo \
RedeclareNoCC1.mo \
RedeclareRecordComponent1.mo \
RedeclareVisibility.mo \
BranchingDynamicPipes.mo \
TestPackageInheritance.mos \



# test that currently fail. Move up when fixed. 
# Run make testfailing
FAILINGTESTFILES=\
ClassExtendsInvalid1.mo \
ConstrainingType1.mo \
ConstrainingType2.mo \
Modification1.mo \
Modification2.mo \
RedeclareClass2.mo \
RedeclareClass3.mo \
RedeclareComponent1.mo \
RedeclareComponent2.mo \
RedeclareComponent3.mo \
RedeclareComponentInvalid1.mo \
RedeclareComponentInvalid2.mo \
RedeclareComponentInvalid3.mo \
RedeclareVisibility2.mo \
ReplaceableBaseClass.mo \

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
TEXI2HTML=texi2html -split_chapter
MAKEINFO=makeinfo

VERSION = $(shell cat VERSION)

.PHONY : default
default : modtest.info modtest.ps $(HTMLFILE)

.PHONY : test clean getdeps failingtest

test :
	@echo
	@echo Running tests...
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
