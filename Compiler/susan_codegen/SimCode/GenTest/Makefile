.PHONY : all trapez

OMC = ../../../../build/bin/omc.exe
#OMC = /c/OpenModelica1.4.5/bin/omc.exe

all : TrapezTest/TrapezTestTotal.cpp trapez 

trapez : 
	@echo " ** Generate TrapezTest Test ** "
	(cd TrapezTest && ../$(OMC) +d=tplmode,tpl2,tplgen_ generate.mos)
	
TrapezTest/TrapezTestTotal.cpp :  TrapezTest/TrapezTestTotal.mo 
	@echo " ** Generate TrapezTest original cpps  ** "
	(cd TrapezTest && ../$(OMC) +d=no_tplmode generate.mos)
 