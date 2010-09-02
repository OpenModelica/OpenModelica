RMLHOME=/usr
COMPILERHOME=../Compiler/
LIBRML=-lrml -lm
ANTLRCMD=java -cp ./antlr-3.2/lib/antlr-3.2.jar org.antlr.Tool -report
CFLAGS=-O3 -g
LDFLAGS=-L$(RMLHOME)/lib/plain/ $(LIBRML) -L. -lantlr3
CPPFLAGS=-I$(COMPILERHOME) -I$(RMLHOME)/include/plain -I. -Iantlr-3.2/runtime/C -Iantlr-3.2/runtime/C/include
CC=gcc

.PHONY: all omc.exe omcd.exe
all: libantlr3.a ModelicaLexer.c ModelicaParser.c ModelicaParser libomparse.a omc.exe omcd.exe

libantlr3.a: antlr-3.2/runtime/C/src/* antlr-3.2/runtime/C/include/* 
	# build the library
	gcc -O3 -c antlr-3.2/runtime/C/src/*.c -Iantlr-3.2/runtime/C/include -Iantlr-3.2/runtime/C
	ar -ru libantlr3.a antlr3*.o
	ranlib libantlr3.a
	rm -f antlr3*.o

ModelicaLexer.o: ModelicaParserCommon.h
ModelicaParser.o: ModelicaParserCommon.h
parse.o: ModelicaLexer.h ModelicaParser.h ModelicaParserCommon.h

libomparse.a: parse.o ModelicaLexer.o ModelicaParser.o 
	ar -ru $@ parse.o ModelicaLexer.o ModelicaParser.o
	ranlib $@

ModelicaLexer.c ModelicaParser.c: Modelica.g
	$(ANTLRCMD) $<

ModelicaParser: libantlr3.a ModelicaLexer.o ModelicaParser.o main.o
	gcc -o $@ main.o ModelicaLexer.o ModelicaParser.o $(LDFLAGS) libantlr3.a
omc.exe:
	(cd ../Compiler/omc_release && g++ -DUSE_CORBA -DUSE_OMNIORB -O3 -o ../../Parser/omc.exe Absyn.o AbsynDep.o Algorithm.o Builtin.o Ceval.o CevalScript.o Cevalfunc.o ClassInf.o ClassLoader.o Connect.o Constants.o ConnectionGraph.o Convert.o DAE.o DAELow.o DAEUtil.o DAEDump.o Derive.o Debug.o DFA.o Dump.o DumpGraphviz.o Env.o Error.o Exp.o ExpandableConnectors.o SCode.o SCodeUtil.o Graphviz.o HashTable.o HashTable2.o HashTable3.o HashTable4.o HashTable5.o HashTable6.o HashTableCG.o HashTableStringToPath.o Inline.o Inst.o InstExtends.o Interactive.o Lookup.o Main.o MMath.o MetaUtil.o Mod.o ModUtil.o PartFn.o Patternm.o Prefix.o PrefixUtil.o Static.o SimCode.o SimCodeC.o SimCodeCSharp.o TplCodegen.o Types.o TaskGraph.o Tpl.o TplAbsyn.o TplParser.o TplMain.o Util.o UnitAbsyn.o UnitAbsynBuilder.o UnitChecker.o Values.o ValuesUtil.o VarTransform.o BackendVarTransform.o Refactor.o DAEQuery.o XMLDump.o InstanceHierarchy.o InnerOuter.o ConnectUtil.o Dependency.o IOStream.o ../../Parser/libomparse.a ../runtime/systemimpl.o ../runtime/systemimplmisc.o ../runtime/dynload.o ../runtime/optmanager.o ../../c_runtime/libc_runtime.a ../runtime/rtopts.o ../runtime/socketimpl.o ../runtime/printimpl.o ../runtime/ptolemyio.o ../runtime/errorext.o ../runtime/ErrorMessage.o ../runtime/daeext.o ../runtime/unitparser.o ../runtime/unitparserext.o ../runtime/corbaimpl.o ../runtime/omc_communication_impl.o ../runtime/omc_communication.o ../modpar/libmodpar.a ../runtime/settingsimpl.o ../runtime/SimulationResults.o ../runtime/IOStreamExt.o -lm -L/usr/lib/plain -lrml_g ../../Parser/libantlr3.a -lomniORB4 -lomnithread -lpthread -llpsolve55 -lcolamd -lm -lreadline  -L../../build/lib/omc  -lsendData -lQtNetwork -lQtCore -lQtGui)
omcd.exe:
	(cd ../Compiler/omc_debug && g++ -DUSE_CORBA -DUSE_OMNIORB -O3 -o ../../Parser/omcd.exe Absyn.o AbsynDep.o Algorithm.o Builtin.o Ceval.o CevalScript.o Cevalfunc.o ClassInf.o ClassLoader.o Connect.o Constants.o ConnectionGraph.o Convert.o DAE.o DAELow.o DAEUtil.o DAEDump.o Derive.o Debug.o DFA.o Dump.o DumpGraphviz.o Env.o Error.o Exp.o ExpandableConnectors.o SCode.o SCodeUtil.o Graphviz.o HashTable.o HashTable2.o HashTable3.o HashTable4.o HashTable5.o HashTable6.o HashTableCG.o HashTableStringToPath.o Inline.o Inst.o InstExtends.o Interactive.o Lookup.o Main.o MMath.o MetaUtil.o Mod.o ModUtil.o PartFn.o Patternm.o Prefix.o PrefixUtil.o Static.o SimCode.o SimCodeC.o SimCodeCSharp.o TplCodegen.o Types.o TaskGraph.o Tpl.o TplAbsyn.o TplParser.o TplMain.o Util.o UnitAbsyn.o UnitAbsynBuilder.o UnitChecker.o Values.o ValuesUtil.o VarTransform.o BackendVarTransform.o Refactor.o DAEQuery.o XMLDump.o InstanceHierarchy.o InnerOuter.o ConnectUtil.o Dependency.o IOStream.o ../../Parser/libomparse.a ../runtime/systemimpl.o ../runtime/systemimplmisc.o ../runtime/dynload.o ../runtime/optmanager.o ../../c_runtime/libc_runtime.a ../runtime/rtopts.o ../runtime/socketimpl.o ../runtime/printimpl.o ../runtime/ptolemyio.o ../runtime/errorext.o ../runtime/ErrorMessage.o ../runtime/daeext.o ../runtime/unitparser.o ../runtime/unitparserext.o ../runtime/corbaimpl.o ../runtime/omc_communication_impl.o ../runtime/omc_communication.o ../modpar/libmodpar.a ../runtime/settingsimpl.o ../runtime/SimulationResults.o ../runtime/IOStreamExt.o -lm -L/usr/lib/plain -lrml_g ../../Parser/libantlr3.a -lomniORB4 -lomnithread -lpthread -llpsolve55 -lcolamd -lm -lreadline  -L../../build/lib/omc  -lsendData -lQtNetwork -lQtCore -lQtGui)
test: ModelicaParser
	sh -c "time ./Release/ModelicaParser -f FullModelica3.1.mo" 

clean:
	rm -f *.o *.a ModelicaParser.c ModelicaParser.h ModelicaLexer.c ModelicaLexer.h ModelicaParser \
	ModelicaParser.exe ./Release/ModelicaParser.exe ./Release/ModelicaParser
	
	 
