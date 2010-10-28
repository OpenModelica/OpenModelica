.PHONY : all 

OMC = OPENMODELICAHOME=`pwd`/../../../build/ ../../../build/bin/omc
#OMC = OPENMODELICAHOME=`pwd`/../../../build/ ../../../build/bin/omc +d=failtrace

all : SimCodeC.mo SimCodeCSharp.mo SimCodeFMU.mo

SimCodeC.mo : SimCodeC.tpl SimCodeTV.mo
	@echo " ** SimCodeC template compilation ** "
	$(OMC) $<
	cp -pf $@ ../../
	@echo " "

SimCodeCSharp.mo : SimCodeCSharp.tpl SimCodeTV.mo
	@echo " ** SimCodeCSharp template compilation ** "
	$(OMC) $<
	cp -pf $@ ../../
	@echo " "

SimCodeFMU.mo : SimCodeFMU.tpl SimCodeTV.mo
	@echo " ** SimCodeFMU template compilation ** "
	$(OMC) $<
	cp -pf $@ ../../
	@echo " "	
