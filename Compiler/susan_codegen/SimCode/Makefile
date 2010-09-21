.PHONY : all 

OMC = OPENMODELICAHOME=`pwd`/../../../build/ ../../../build/bin/omc

all : SimCodeC.mo SimCodeCSharp.mo

SimCodeC.mo : SimCodeC.tpl SimCodeTV.mo
	@echo " ** SimCodeC template compilation ** "
	$(OMC) +d=failtrace $<
	cp -pf $@ ../../
	@echo " "

SimCodeCSharp.mo : SimCodeCSharp.tpl
	@echo " ** SimCodeCSharp template compilation ** "
	$(OMC) +d=failtrace $<
	cp -pf $@ ../../
	@echo " "
