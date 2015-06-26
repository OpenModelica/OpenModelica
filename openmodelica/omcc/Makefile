OMC=../../../build/bin/omc

default: parser

all: $(GEN_FILES)

LexerModelica.mo: OMCC.mos lexerModelica.l parserModelica.y LexerGenerator.mo ParserGenerator.mo OMCC.mo LexerCode.tmo ParseCode.tmo OMCCBaseLexer.mo OMCCTypes.mo Parser.mo
	$(OMC) $<

omcc:
	rm -f OMCC_main.makefile
	$(OMC) OMCC.mos
	$(MAKE) -f OMCC_main.makefile MODELICAUSERCFLAGS='-DGENERATE_MAIN_EXECUTABLE -Os'
	$(CC) -o OMCC OMCC_main.so '-Wl,-rpath,$$ORIGIN'

Main_main.so: GenerateParser.mos $(GEN_FILES) Main.mo
	@rm -f $@
	$(OMC) $<

parser: Main_main.so
	$(CC) -g -O2 -o $@ $< '-Wl,-rpath,$$ORIGIN'

parser-all: omcc
	./OMCC Modelica
	$(MAKE) parser

lexer: LexerTest_main.so
	$(CC) -g -O2 -o $@ $< '-Wl,-rpath,$$ORIGIN'

LexerTest_main.so: LexerTest.mos LexerTest.mo LexerModelica.mo LexerCodeModelica.mo LexTableModelica.mo TokenModelica.mo
	rm -f LexerTest_main.makefile
	$(OMC) $<
	$(MAKE) -f LexerTest_main.makefile
lexer-all: omcc
	./OMCC --lexer-only Modelica
	$(MAKE) lexer

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
