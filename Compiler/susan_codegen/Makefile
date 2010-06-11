.PHONY : all

OMC = ../../build/bin/omc

all : TplCodegen.mo
TplCodegen.mo : TplCodegen.tpl
	@echo " ** Susan Test ** "
	$(OMC) +d=failtrace TplCodegen.tpl
	cp -puf TplCodegen.mo ../
	@echo " "
