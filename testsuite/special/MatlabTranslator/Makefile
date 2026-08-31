# Probe the omc of a CMake build, first hit wins
OMC_CANDIDATES := ../../../build/install_cmake/bin/omc \
                  ../../../build_cmake/install_cmake/bin/omc \
                  ../../../build/bin/omc
OMC := $(firstword $(realpath $(wildcard $(OMC_CANDIDATES))) $(lastword $(OMC_CANDIDATES)))

# Susan writes AbsynDumpTpl.mo into the build tree, or in-source for an in-source build
OMC_GENERATED_MO_CANDIDATES := ../../../build_cmake/OMCompiler/Compiler/generated-mo \
                               ../../../build/OMCompiler/Compiler/generated-mo \
                               ../../../OMCompiler/Compiler
OMCOMPILERGENERATEDSOURCES := $(firstword $(realpath $(wildcard $(OMC_GENERATED_MO_CANDIDATES))) $(lastword $(OMC_GENERATED_MO_CANDIDATES)))

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
