OMC = ../../../build/bin/omc

test:
	@echo Running RMLTranslator
	@$(OMC) SCRIPT.mos 
	
parser:
	@echo Genereating lexer and parser components
	@$(OMC) OMCC.mos 
	

GEN_FILES=LexerModelica.mo LexTableModelica.mo LexerCodeModelica.mo ParserModelica.mo ParseTableModelica.mo ParseCodeModelica.mo TokenModelica.mo


DEPENDENCIES = \
*.mo \
*.mos \
rmltests   \
lexerModelica.l \
parserModelica.y \
ParseCode.tmo \
LexerCode.tmo \
Readme.txt \
Makefile 
	
CLEAN = `ls | grep -w -v -f deps.tmp`

# Cleans all files that are not listed as dependencies 
clean :
	@echo $(DEPENDENCIES) | sed 's/ /\\|/g' > deps.tmp
	@rm -f $(CLEAN)

