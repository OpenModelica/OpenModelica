.PHONY : all

OMC = ../../../build/bin/omc.exe

all :
	@echo " ** SimCodeC template compilation ** "
	$(OMC) +d=failtrace SimCodeC.tpl
	cp -puf SimCodeC.mo ../../
	@echo " "
	@echo " ** SimCodeCSharp template compilation ** "
	$(OMC) +d=failtrace SimCodeCSharp.tpl
	cp -puf SimCodeCSharp.mo ../../
	