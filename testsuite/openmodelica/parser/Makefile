TEST=../../rtest -v

ifeq ($(shell uname -m),x86_64)
	ARCH_DEPENDENT_FILES=IntegerLiterals64.mo
else
	ARCH_DEPENDENT_FILES=IntegerLiterals32.mo
endif

TESTFILES=\
$(ARCH_DEPENDENT_FILES) \
Assign1.mo \
Assign2.mo \
Assign3.mo \
Assign4.mo \
Class3.mo \
Class4.mo \
Code.mo \
ConstructParameters1.mo \
Declaration1.mo \
Declaration2.mo \
Declaration3.mo \
DocumentationBackslash.mo \
DotName.mos \
EmptyWithin.mo \
Identifier.mo \
IfElseIf.mo \
ImportFullyQualified.mo \
InvalidPartialFunction.mo \
MetaModelicaMatchElse.mo \
MetaModelicaStringOpModelicaLexer.mo \
MissingEquation.mo \
MissingSemicolon.mo \
ModifyConstant3.mo \
OptionalOutput.mos \
ParseElementReplaceable.mo \
ParseError1.mo \
ParseError2.mo \
ParseError3.mo \
ParseFullModelica2.2.2.mos \
ParseFullModelica3.1.mos \
ParseFullModelica3.2.1.mos \
ParseString.mos \
PureImpure.mo \
RealOpLexerModelica.mo \
Redeclare.mos \
ReloadClass.mos \
SimpleIntegrator4.mo \
WildLexerModelica.mo \
WildLexerMetaModelica.mo \
ParseModel.mos

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

# Get the dependency files
getdeps: 
	@echo $(DEPENDENCIES) | sed 's/ /\\|/g' > deps.tmp
	@echo $(CLEAN) | sed -r 's/deps.txt|deps.tmp//g' | sed 's/ / \\\n/g' > deps.txt	
	@echo Dependency list saved in deps.txt.
	@echo Copy the list from deps.txt and add it to the Makefile @DEPENDENCIES

failingtest :
	@$(TEST) $(FAILINGTESTFILES)
