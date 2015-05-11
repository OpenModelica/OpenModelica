TEST=../../rtest -v

OPENMODELICAHOME := $(shell pwd)/../../../build
TESTFILES=JavaExt.mos JavaExtArrays.mos JavaExtInteractive.mos JavaExtRecord.mos JavaExtUniontype.mos JavaExtParseProgram.mos
SEP=$(shell test -e "`which mingw32-gcc.exe`" && echo ";" || echo ":")
LDL=$(shell test -e "`which mingw32-gcc.exe`" && echo "" || echo "-ldl")
RUNTIME=$(OPENMODELICAHOME)/share/omc/java/modelica_java.jar
ANTLR=$(OPENMODELICAHOME)/share/omc/java/antlr-3.2.jar
OMC=$(OPENMODELICAHOME)/bin/omc
CLASSPATH=JavaExtDefs.jar$(SEP)AbsynTest.jar$(SEP).$(SEP)$(RUNTIME)
CLEAN=JavaTest_*
ifdef JAVA_HOME
JAVAC=$(JAVA_HOME)/bin/javac
JAVA=$(JAVA_HOME)/bin/java
else
JAVAC=javac
JAVA=java
endif
test: check defs clean
	@echo
	@echo Running tests...
	@echo
	@echo OPENMODELICAHOME = $$OPENMODELICAHOME
	@echo JAVA_HOME = $$JAVA_HOME
	CLASSPATH="$(CLASSPATH)" $(TEST) $(TESTFILES)
	$(RM) -f JavaTest_*
interactivetest: check defs
	@$(TEST) JavaExtInteractive.mos
failingtest : check defs
	@echo
	@echo Running failing tests...
	@echo
	@$(TEST) $(FAILINGTESTFILES)
check:
	@echo Checking if JRE is installed
	@$(TEST) JavaTest.mos GetDefinitions.mos || (echo "Skipping Java testsuite. Install Java JDK or add the Java installation directory to the JAVA_HOME environment variable." && false)
defs: check_javac JavaExtDefs.jar AbsynTest.jar JavaExt.class
check_javac:
	@"$(JAVAC)" -version 2>version.txt || (echo "No Java Compiler found." && echo "Install a Java Development Kit (JDK) and set JAVA_HOME to that location." && echo "Sun Java installs both JRE and JDK in Windows, but we MUST load the JDK so we can access javac." && false)
JavaExtDefs.jar: JavaExt.mo $(OMC) $(RUNTIME)
	"$(JAVA)" -classpath "$(RUNTIME)$(SEP)$(ANTLR)" org.openmodelica.corba.parser.DefinitionsCreator $@ org.openmodelica.JavaExtTest "." $<
AbsynTest.jar: ../../../OMCompiler/Compiler/FrontEnd/Absyn.mo $(OMC) $(RUNTIME)
	OPENMODELICAHOME=$(OPENMODELICAHOME) "$(JAVA)" -classpath "$(RUNTIME)$(SEP)$(ANTLR)" org.openmodelica.corba.parser.DefinitionsCreator $@ org.openmodelica.AbsynTest "." $<
JavaExt.class: JavaExt.java JavaExtDefs.jar AbsynTest.jar $(OMC) $(RUNTIME)
	"$(JAVAC)" -classpath "$(CLASSPATH)" $<

clean:
	rm -f $(CLEAN)

# To debug the JavaExtInteractive session; it has more test cases than the other mos files...
JavaExtInteractiveTrace.mos: JavaExtInteractiveTrace.txt
	echo "loadFile(\"JavaExt.mo\");" > $@
	grep "^>>" $< | sed "s/^>> //" | sed "s/$$/;/" >> $@
# Used to test the data types we can't test in real OMC right now
dummytest:
	gcc -o dummy dummy_test.c -I../../../build/include/ ../../../build/lib/libSimulationRuntimeC.a $(LDL)
	dummy | diff -w dummy_test_expected.txt -
	rm -f dummy dummy.exe
