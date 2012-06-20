.PHONY : all 

OMC = OPENMODELICAHOME=`pwd`/../../build/ ../../build/bin/omc +d=failtrace

all : AbsynDumpTpl.mo CodegenUtil.mo CodegenC.mo CodegenFMU.mo CodegenCSharp.mo CodegenQSS.mo CodegenCpp.mo DAEDumpTpl.mo ExpressionDumpTpl.mo SimCodeDump.mo Unparsing.mo SCodeDumpTpl.mo CodegenAdevs.mo

AbsynDumpTpl.mo : AbsynDumpTpl.tpl AbsynDumpTV.mo
	@echo " ** AbsynDumpTpl template compilation ** "
	$(OMC) $< > $@.log || (cat $@.log && false)
	@echo " "	

CodegenAdevs.mo : CodegenAdevs.tpl SimCodeTV.mo
	@echo " ** CodegenAdevs template compilation ** "
	$(OMC) $< > $@.log || (cat $@.log && false)
	@echo " "

CodegenUtil.mo : CodegenUtil.tpl SimCodeTV.mo
	@echo " ** CodegenUtil template compilation ** "
	$(OMC) $< > $@.log || (cat $@.log && false)
	@echo " "	
	
CodegenC.mo : CodegenC.tpl SimCodeTV.mo
	@echo " ** CodegenC template compilation ** "
	$(OMC) $< > $@.log || (cat $@.log && false)
	@echo " "

CodegenCSharp.mo : CodegenCSharp.tpl SimCodeTV.mo
	@echo " ** CodegenCSharp template compilation ** "
	$(OMC) $< > $@.log || (cat $@.log && false)
	@echo " "
		
CodegenFMU.mo : CodegenFMU.tpl SimCodeTV.mo CodegenC.tpl
	@echo " ** CodegenFMU template compilation ** "
	$(OMC) $< > $@.log || (cat $@.log && false)
	@echo " "
		
DAEDumpTpl.mo : DAEDumpTpl.tpl DAEDumpTV.mo
	@echo " ** DAEDumpTpl template compilation ** "
	$(OMC) $< > $@.log || (cat $@.log && false)
	@echo " "

Unparsing.mo : Unparsing.tpl SimCodeTV.mo
	@echo " ** Unparsing template compilation ** "
	$(OMC) $< > $@.log || (cat $@.log && false)
	@echo " "	

SimCodeDump.mo : SimCodeDump.tpl SimCodeTV.mo CodegenC.tpl
	@echo " ** SimCodeDump template compilation ** "
	$(OMC) $< > $@.log || (cat $@.log && false)
	@echo " "	

CodegenQSS.mo : CodegenQSS.tpl SimCodeTV.mo CodegenC.tpl 
	@echo " ** CodegenQSS template compilation ** "
	$(OMC) $< > $@.log || (cat $@.log && false)
	@echo " "	

CodegenCpp.mo : CodegenCpp.tpl SimCodeTV.mo
	@echo " ** CodegenCpp template compilation ** "
	$(OMC) $< > $@.log || (cat $@.log && false)
	@echo " "	

ExpressionDumpTpl.mo : ExpressionDumpTpl.tpl ExpressionDumpTV.mo DAEDumpTpl.tpl
	@echo " ** ExpressionDumpTpl template compilation ** "
	$(OMC) $< > $@.log || (cat $@.log && false)
	@echo " "	

SCodeDumpTpl.mo : SCodeDumpTpl.tpl SCodeTV.mo AbsynDumpTpl.tpl
	@echo " ** SCodeDumpTpl template compilation ** "
	$(OMC) $< > $@.log || (cat $@.log && false)
	@echo " "	
