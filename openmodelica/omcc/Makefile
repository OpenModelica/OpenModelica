OMC=../../../build/bin/omc

GEN_FILES=LexerModelica.mo LexTableModelica.mo LexerCodeModelica.mo ParserModelica.mo ParseTableModelica.mo ParseCodeModelica.mo TokenModelica.mo

default: parser

all: $(GEN_FILES)

LexerModelica.mo: OMCC.mos lexerModelica.l parserModelica.y LexerGenerator.mo ParserGenerator.mo OMCC.mo Absyn.mo LexerCode.tmo ParseCode.tmo Lexer.mo Types.mo Parser.mo
	$(OMC) $<

Main_main.so: GenerateParser.mos $(GEN_FILES) Main.mo
	@rm -f $@
	$(OMC) $<

parser: Main_main.so
	$(CC) -g -O2 -o $@ $< -lhwloc '-Wl,-rpath,$$ORIGIN'

.PHONY: ModelicaParserTests

TESTREV=541706f5c8c40a4ab61a5739e294e3d4b6f8696d

ModelicaParserTests:
	@test -d ModelicaParserTests || git clone https://github.com/OpenModelica/ModelicaParserTests
	@cd ModelicaParserTests && (git checkout -q $(TESTREV) || (git fetch && git checkout $(TESTREV)))

FAIL=$(wildcard ModelicaParserTests/should_fail/*.mo)
WORK=$(wildcard ModelicaParserTests/should_work/*.mo)

test: ModelicaParserTests
	$(MAKE) test-internal
test-internal: $(FAIL:%.mo=%.testfail) $(WORK:%.mo=%.testsuccess)

%.testfail: %.mo
	@echo "$<" | sed "s,.*/,Parsing ,"
	@! ./parser "$<" Modelica > /dev/null 2>&1
%.testsuccess: %.mo
	@echo "$<" | sed "s,.*/,Parsing ,"
	@./parser "$<" Modelica > /dev/null 2>&1
