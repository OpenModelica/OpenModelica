# BuiltinReal.mos fails when using Cevalfunc.mo! the values are OK, the display is different!
TEST = ../../rtest -v


ifeq ($(OMDEV),)
	PATH := ./:${PATH}
else
	# this DOES NOT WORK ON WINDOWS! PATH := ./;${PATH}
endif

TESTFILES = \
  ArrayBinding1.mo \
	Comments.mo \
  DoublePendulum.mos \
	Expression1.mo \
	InStreamNominalThreshold.mo \
	MoveBindings1.mo \
	NonScalarizedWithRecords1.mo \
	NonScalarizedWithoutRecords1.mo \
	PartiallyScalarizedWithRecords1.mo \
	PartiallyScalarizedWithoutRecords1.mo \
	Record1.mo \
	Record2.mo \
	Record3.mo \
	Scalarize1.mo \
	Scalarize2.mo \
	Scalarize3.mo \
	Scalarize4.mo \
	Scalarize5.mo \
	Scalarize6.mo \
	Scalarize7.mo \
	ScalarizedWithRecords1.mo \
	ScalarizedWithoutRecords1.mo \
	SD.mo \
	SimpleCoolingCycle.mo \
  Tables.mos \
	Tuple1.mo \
	Tuple2.mo \


# test that currently fail. Move up when fixed.
# Run make testfailing
FAILINGTESTFILES= \

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
