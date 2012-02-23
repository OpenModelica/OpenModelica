.PHONY : all 

OMC = OPENMODELICAHOME=`pwd`/../../../build/ ../../../build/bin/omc +d=failtrace

all : CodegenC.mo CodegenFMU.mo CodegenCSharp.mo CodegenQSS.mo CodegenCpp.mo SimCodeDump.mo Unparsing.mo SCodeDumpTpl.mo CodegenAdevs.mo

CodegenAdevs.mo : CodegenAdevs.tpl SimCodeTV.mo
	@echo " ** CodegenAdevs template compilation ** "
	$(OMC) $< > $@.log || (cat $@.log && false)
	cp -pf $@ ../../Template/
	@echo " "

CodegenC.mo : CodegenC.tpl SimCodeTV.mo
	@echo " ** CodegenC template compilation ** "
	$(OMC) $< > $@.log || (cat $@.log && false)
	cp -pf $@ ../../Template/
	@echo " "

CodegenCSharp.mo : CodegenCSharp.tpl SimCodeTV.mo
	@echo " ** CodegenCSharp template compilation ** "
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

CodegenQSS.mo : CodegenQSS.tpl SimCodeTV.mo CodegenC.tpl 
	@echo " ** CodegenQSS template compilation ** "
	$(OMC) $< > $@.log || (cat $@.log && false)
	cp -pf $@ ../../Template/
	@echo " "	

CodegenCpp.mo : CodegenCpp.tpl SimCodeTV.mo
	@echo " ** CodegenCpp template compilation ** "
	$(OMC) $< > $@.log || (cat $@.log && false)
	cp -pf $@ ../../Template/
	@echo " "	

SCodeDumpTpl.mo : SCodeDumpTpl.tpl SCodeTV.mo
	@echo " ** SCodeDumpTpl template compilation ** "
	$(OMC) $< > $@.log || (cat $@.log && false)
	cp -pf $@ ../../Template/
	@echo " "	
