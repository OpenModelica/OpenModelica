TEST=../../../rtest -v

TESTFILES=\
ArrayModif.mo \
ArrayModTypeError.mo \
ArrayModTypeError2.mo \
Bug3817.mos \
DisturbedResistance1.mo \
DisturbedResistance3.mo \
DisturbedResistance4.mo \
DuplicateBaseTypeMod.mo \
DuplicateMod1.mo \
DuplicateMod2.mo \
DuplicateMod3.mo \
DuplicateMod4.mo \
DuplicateMod5.mo \
DuplicateMod6.mo \
DuplicateMod7.mo \
FinalMod1.mo \
FinalParameterModification.mo \
FixedFalse.mo \
MissingModifiers.mo \
MissingModifiersPackages.mo \
Modification1.mo \
Modification2.mo \
Modification3.mo \
Modification4.mo \
Modification5.mo \
Modification6.mo \
Modification7.mo \
Modification8.mo \
Modification10.mo \
Modification11.mo \
Modification12.mo \
Modification13.mo \
Modification14.mo \
Modification15.mo \
Modification16.mo \
Modification17.mo \
ModifierClass.mo \
ModifierExtends.mo \
ModifierProblem.mo \
ModifierRedeclare.mo \
ModifierSubModMerging1.mo \
ModifierTypeError.mo \
ModifierVariable.mo \
ModifyConstant4.mo \
ModifyConstant5.mo \
ModifyFunction1.mo \
modifyOuter.mo \
modifyOuter2.mo \
ModifyUnknown1.mo \
ModifyUnknown2.mo \
Overwriting1.mo \
Overwriting2.mo \
Shadow1.mo \
UsertypeModifications.mo \
UsertypeArrayMod.mo \
TestMissingModifiers.mos \
TupleFuncMod.mo


# test that currently fail. Move up when fixed.
# Run make testfailing
FAILINGTESTFILES=\
DisturbedResistance2.mo \
ReplaceFunction.mo \
ModifyConstant6.mo \


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
