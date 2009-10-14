include Makefile.common

antlr_compile = java -jar $(antlr) -fo src/org/openmodelica/corba/parser

install: modelica_java.jar $(antlr)
	cp $< $(antlr) ../../build/share/java
modelica_java.jar: $(java_sources)
	rm -rf bin-jar; mkdir bin-jar
	javac -cp "$(antlr)" -d bin-jar $(java_sources)
	jar cf $@ $(java_sources:src/%=-C src %) $(resources:src/%=-C src %) -C bin-jar . || (rm $@ && false)
test: $(java_sources)
	rm -rf bin-test; mkdir bin-test
	javac -cp "$(antlr):$(junit)" -d bin-test $(java_sources) $(java_tests)
	java -cp "bin-test:src:$(antlr):$(junit)" org.junit.runner.JUnitCore $(junit_tests)
%Lexer.java: %.g
	$(antlr_compile) $<
%Parser.java: %.g
	$(antlr_compile) $<
%.tokens: %.g
	$(antlr_compile) $<
