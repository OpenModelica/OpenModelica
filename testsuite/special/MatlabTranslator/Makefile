
OPENMODELICA_ROOT = $(CURDIR)/../../../
# OMPython needs this
OPENMODELICAHOME := $(shell                                     \
	if [ -d $(OPENMODELICA_ROOT)/build_cmake/install ];           \
		then echo '$(OPENMODELICA_ROOT)/build_cmake/install';       \
	elif [ -d $(OPENMODELICA_ROOT)/build_cmake/install_cmake ];   \
		then echo '$(OPENMODELICA_ROOT)/build_cmake/install_cmake'; \
	elif [ -d $(OPENMODELICA_ROOT)/install_cmake ];               \
		then echo '$(OPENMODELICA_ROOT)/install_cmake';             \
	else                                                          \
		echo '$(OPENMODELICA_ROOT)/build/'; fi)

OMC = $(OPENMODELICAHOME)/bin/omc

test:
	@echo Running MatlabTranslator
	@$(OMC) SCRIPT.mos

parser:
	@echo Genereating lexer and parser components
	@$(OMC) OMCC.mos


GEN_FILES=LexerModelica.mo LexTableModelica.mo LexerCodeModelica.mo ParserModelica.mo ParseTableModelica.mo ParseCodeModelica.mo TokenModelica.mo


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

