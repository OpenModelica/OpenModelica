OMC := $(shell test -e ../../../build/install_cmake/bin/omc && echo ../../../build/install_cmake/bin/omc \
               || echo ../../../build_cmake/install_cmake/bin/omc )
OMC := $(shell realpath $(OMC))

OMC_GENERATED_MO_DIR := $(shell test -e ../../../build_cmake/OMCompiler/Compiler/generated-mo/Template/AbsynDumpTpl.mo && echo ../../../build_cmake/OMCompiler/Compiler/generated-mo \
                                || echo ../../../build/OMCompiler/Compiler/generated-mo)
OMC_GENERATED_MO_DIR := $(shell realpath $(OMC_GENERATED_MO_DIR))

test:
	@echo Running MatlabTranslator
	@OMC_GENERATED_MO_DIR=$(OMC_GENERATED_MO_DIR) $(OMC) SCRIPT.mos

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
