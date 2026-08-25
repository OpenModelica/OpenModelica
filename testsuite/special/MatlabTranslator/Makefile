OMC ?= $(firstword $(wildcard ../../../build/install_cmake/bin/omc \
                              ../../../build_cmake/install_cmake/bin/omc \
                              ../../../build/bin/omc))
OMC := $(realpath $(OMC))

# ?= already means "only if the caller did not set it", so this must not mention
# OMCOMPILERGENERATEDSOURCES on the right-hand side: ?= defines a recursively
# expanded variable, and referencing itself there is a self-reference error.
OMCOMPILERGENERATEDSOURCES ?= $(firstword $(wildcard ../../../build_cmake/OMCompiler/Compiler/generated-mo \
                                                     ../../../build/OMCompiler/Compiler/generated-mo))
OMCOMPILERGENERATEDSOURCES := $(realpath $(OMCOMPILERGENERATEDSOURCES))

.PHONY: test parser clean

test:
	@echo Running MatlabTranslator
	@OMCOMPILERGENERATEDSOURCES=$(OMCOMPILERGENERATEDSOURCES) $(OMC) SCRIPT.mos

parser:
	@echo Genereating lexer and parser components
	@$(OMC) OMCC.mos

DEPENDENCIES = \
*.mo \
*.mos \
Workingexamples \
Readme.txt \
lexerModelica.l \
parserModelica.y \
ParseCode.tmo \
LexerCode.tmo \
Makefile

CLEAN = `ls | grep -w -v -f deps.tmp`

# Cleans all files that are not listed as dependencies
clean :
	@echo $(DEPENDENCIES) | sed 's/ /\\|/g' > deps.tmp
	@rm -f $(CLEAN)
