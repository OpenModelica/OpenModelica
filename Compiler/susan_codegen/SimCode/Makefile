.PHONY : all 

OMC = OPENMODELICAHOME=`pwd`/../../../build/ ../../../build/bin/omc

all : SimCodeC.mo SimCodeCSharp.mo

SimCodeC.mo : SimCodeC.tpl
	@echo " ** SimCodeC template compilation ** "
	$(OMC) +d=failtrace SimCodeC.tpl
	cp -pf SimCodeC.mo ../../
	@echo " "

SimCodeCSharp.mo : SimCodeCSharp.tpl
	@echo " ** SimCodeCSharp template compilation ** "
	$(OMC) +d=failtrace SimCodeCSharp.tpl
	cp -pf SimCodeCSharp.mo ../../
	@echo " "
