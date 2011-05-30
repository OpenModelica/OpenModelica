.PHONY : all 

OMC = OPENMODELICAHOME=`pwd`/../../../build/ ../../../build/bin/omc +d=failtrace


all : SimCodeC.mo SimCodeCSharp.mo SimCodeFMU.mo Unparsing.mo SimCodeQSS.mo SimCodeCpp.mo SimCodeDump.mo SCodeDumpTpl.mo



SimCodeC.mo : SimCodeC.tpl SimCodeTV.mo
	@echo " ** SimCodeC template compilation ** "
	$(OMC) $< > $@.log || (cat $@.log && false)
	cp -pf $@ ../../Template/
	@echo " "

SimCodeCSharp.mo : SimCodeCSharp.tpl SimCodeTV.mo
	@echo " ** SimCodeCSharp template compilation ** "
	$(OMC) $< > $@.log || (cat $@.log && false)
	cp -pf $@ ../../Template/
	@echo " "

SimCodeFMU.mo : SimCodeFMU.tpl SimCodeTV.mo
	@echo " ** SimCodeFMU template compilation ** "
	$(OMC) $< > $@.log || (cat $@.log && false)
	cp -pf $@ ../../Template/
	@echo " "	

Unparsing.mo : Unparsing.tpl SimCodeTV.mo
	@echo " ** Unparsing template compilation ** "
	$(OMC) $< > $@.log || (cat $@.log && false)
	cp -pf $@ ../../Template/
	@echo " "	

SimCodeDump.mo : SimCodeDump.tpl SimCodeTV.mo
	@echo " ** SimCodeDump template compilation ** "
	$(OMC) $< > $@.log || (cat $@.log && false)
	cp -pf $@ ../../Template/
	@echo " "	

SimCodeQSS.mo : SimCodeQSS.tpl SimCodeTV.mo
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
