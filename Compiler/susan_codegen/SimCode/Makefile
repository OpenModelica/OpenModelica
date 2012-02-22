.PHONY : all 

OMC = OPENMODELICAHOME=`pwd`/../../../build/ ../../../build/bin/omc +d=failtrace

all : CodegenC.mo CodegenFMU.mo SimCodeC.mo SimCodeCSharp.mo SimCodeFMU.mo Unparsing.mo SimCodeQSS.mo SimCodeCpp.mo SimCodeDump.mo SCodeDumpTpl.mo SimCodeAdevs.mo

SimCodeC.mo : SimCodeC.tpl SimCodeTV.mo
	@echo " ** SimCodeC template compilation ** "
	$(OMC) $< > $@.log || (cat $@.log && false)
	cp -pf $@ ../../Template/
	@echo " "

SimCodeAdevs.mo : SimCodeAdevs.tpl SimCodeTV.mo
	@echo " ** SimCodeAdevs template compilation ** "
	$(OMC) $< > $@.log || (cat $@.log && false)
	cp -pf $@ ../../Template/
	@echo " "

CodegenC.mo : CodegenC.tpl SimCodeTV.mo
	@echo " ** CodegenC template compilation ** "
	$(OMC) $< > $@.log || (cat $@.log && false)
	cp -pf $@ ../../Template/
	@echo " "

SimCodeCSharp.mo : SimCodeCSharp.tpl SimCodeTV.mo
	@echo " ** SimCodeCSharp template compilation ** "
	$(OMC) $< > $@.log || (cat $@.log && false)
	cp -pf $@ ../../Template/
	@echo " "

SimCodeFMU.mo : SimCodeFMU.tpl SimCodeTV.mo SimCodeC.tpl
	@echo " ** SimCodeFMU template compilation ** "
	$(OMC) $< > $@.log || (cat $@.log && false)
	cp -pf $@ ../../Template/
	@echo " "
		
CodegenFMU.mo : CodegenFMU.tpl SimCodeTV.mo CodegenC.tpl
	@echo " ** CodegenFMU template compilation ** "
	$(OMC) $< > $@.log || (cat $@.log && false)
	cp -pf $@ ../../Template/
	@echo " "

Unparsing.mo : Unparsing.tpl SimCodeTV.mo
	@echo " ** Unparsing template compilation ** "
	$(OMC) $< > $@.log || (cat $@.log && false)
	cp -pf $@ ../../Template/
	@echo " "	

SimCodeDump.mo : SimCodeDump.tpl SimCodeTV.mo CodegenC.tpl
	@echo " ** SimCodeDump template compilation ** "
	$(OMC) $< > $@.log || (cat $@.log && false)
	cp -pf $@ ../../Template/
	@echo " "	

SimCodeQSS.mo : SimCodeQSS.tpl SimCodeTV.mo SimCodeC.tpl 
	@echo " ** SimCodeQSS template compilation ** "
	$(OMC) $< > $@.log || (cat $@.log && false)
	cp -pf $@ ../../Template/
	@echo " "	

SimCodeCpp.mo : SimCodeCpp.tpl SimCodeTV.mo
	@echo " ** SimCodeCpp template compilation ** "
	$(OMC) $< > $@.log || (cat $@.log && false)
	cp -pf $@ ../../Template/
	@echo " "	

SCodeDumpTpl.mo : SCodeDumpTpl.tpl SCodeTV.mo
	@echo " ** SCodeDumpTpl template compilation ** "
	$(OMC) $< > $@.log || (cat $@.log && false)
	cp -pf $@ ../../Template/
	@echo " "	
