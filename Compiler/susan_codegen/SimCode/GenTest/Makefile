.PHONY : all tplmode csharp cppOrig

OMC = ../../../../build/bin/omc.exe
#OMC = /c/OpenModelica1.4.5/bin/omc.exe

all :  tplmode  csharp  cppOrig

	
tplmode : 
	@echo " ** Generate TrapezTest Test ** "
	(cd TrapezTest && ../$(OMC) +d=tplmode,tpl2,tplgen_ generate.mos)
	#@echo " ** Generate RightHeartStarling Test C/C++ target ** "
	#(cd RightHeartStarling && ../$(OMC) +d=tplmode,tpl2,tplgen_ generate.mos)

csharp :
	@echo " ** Generate RightHeartStarling Test CSharp target ** "
	(cd RightHeartStarling && ../$(OMC) +d=tplmode,CSharp generate.mos)
	@echo " ** Generate TrapezUnderground Test CSharp target ** "
	(cd TrapezUnderground && ../$(OMC) +d=tplmode,CSharp generate.mos)

cppOrig :
	#@echo " ** Generate TrapezTest original original C/C++ target  ** "
	#(cd TrapezTest && ../$(OMC) +d=no_tplmode generate.mos)
	@echo " ** Simulate TrapezUnderground Test original C/C++ target ** "
	(cd TrapezUnderground && ../$(OMC) +d=no_tplmode simulate.mos)
	@echo " ** Simulate RightHeartStarling original C/C++   ** "
	(cd RightHeartStarling && ../$(OMC) +d=no_tplmode simulate.mos)
    
#RightHeartStarling/RightHeartStarling.cpp :  RightHeartStarling/RightHeartStarling.mo 
#	@echo " ** Generate RightHeartStarling original cpps  ** "
#	(cd RightHeartStarling && ../$(OMC) +d=no_tplmode generate.mos)
 