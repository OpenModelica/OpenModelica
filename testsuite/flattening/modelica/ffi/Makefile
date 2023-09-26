TEST=../../../rtest -v

TESTFILES=\
ArrayResult1.mos \
Boolean1.mos \
Boolean2.mos \
Enum1.mos \
Enum2.mos \
Enum3.mos \
Exception1.mos \
Integer1.mos \
Integer2.mos \
MissingFunction1.mos \
ModelicaInternal_countLines.mos \
ModelicaIO_readRealMatrix.mos \
ModelicaStrings_scanInteger.mos \
ModelicaStrings_scanReal.mos \
ModelicaStrings_scanString.mos \
OpenModelica_regex.mos \
Real1.mos \
Real2.mos \
Real3.mos \
RealArray1.mos \
Record1.mos \
Record2.mos \
Record3.mos \
Record4.mos \
String1.mos \
String2.mos \
StringArray1.mos \

# test that currently fail. Move up when fixed.
# Run make testfailing
FAILINGTESTFILES=\
Record5.mos \
Crash1.mos

# Dependency files that are not .mo .mos or Makefile
# Add them here or they will be cleaned.
DEPENDENCIES = \
*.mo \
*.mos \
Makefile

CLEAN = `ls | grep -w -v -f deps.tmp`

VERSION = $(shell cat VERSION)

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
