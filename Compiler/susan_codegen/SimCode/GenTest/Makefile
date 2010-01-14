.PHONY : all trapez starl

OMC = ../../../../build/bin/omc.exe
#OMC = /c/OpenModelica1.4.5/bin/omc.exe

all : TrapezTest/TrapezTestTotal.cpp trapez  RightHeartStarling/RightHeartStarling.cpp starl

trapez : 
	@echo " ** Generate TrapezTest Test ** "
	(cd TrapezTest && ../$(OMC) +d=tplmode,tpl2,tplgen_ generate.mos)
	
TrapezTest/TrapezTestTotal.cpp :  TrapezTest/TrapezTestTotal.mo 
	@echo " ** Generate TrapezTest original cpps  ** "
	(cd TrapezTest && ../$(OMC) +d=no_tplmode generate.mos)

starl : 
	#@echo " ** Generate RightHeartStarling Test C/C++ target ** "
	#(cd RightHeartStarling && ../$(OMC) +d=tplmode,tpl2,tplgen_ generate.mos)
	@echo " ** Generate RightHeartStarling Test CSharp target ** "
	(cd RightHeartStarling && ../$(OMC) +d=tplmode,CSharp generate.mos)
    
RightHeartStarling/RightHeartStarling.cpp :  RightHeartStarling/RightHeartStarling.mo 
	@echo " ** Generate RightHeartStarling original cpps  ** "
	(cd RightHeartStarling && ../$(OMC) +d=no_tplmode generate.mos)
 