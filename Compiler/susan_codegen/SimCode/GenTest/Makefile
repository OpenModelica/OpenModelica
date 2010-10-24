.PHONY : all tplmode csharp cppOrig QHP beatheart csCopy tst

OMC = ../../../../build/bin/omc.exe
#OMC = /d/Modelica/_modely/MM_for_debug/omc.exe
#OMC = /c/OpenModelica1.4.5/bin/omc.exe
ModelsNET = "/d/Modelica/_svn_Solvers/Compiled Solvers/Simulation/ModelsDotNet/"
#all :  tplmode  csharp  cppOrig
all :  QHP csCopy
#all : csharp csCopy
#all :  tst
#all :  cppOrig

tst:
	#(cd ../../../../testsuite/mosfiles/ && ../../build/bin/omc.exe BuiltinMath.mos 2>&1)
	(cd ../../../../testsuite/mofiles/ && ../../build/bin/omc.exe ArrayAssignWholeDim.mo > ArrayAssignWholeDim.mof  2>&1)
	(cd ../../../../testsuite/mofiles/ && ../../build/bin/omc.exe VectorTest.mo > VectorTest.mof  2>&1)
	
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
	#@echo " ** Simulate TrapezUnderground Test original C/C++ target ** "
	#(cd TrapezUnderground && ../$(OMC) +d=no_tplmode simulate.mos)
	#@echo " ** Simulate RightHeartStarling original C/C++   ** "
	#(cd RightHeartStarling && ../$(OMC) +d=no_tplmode simulate.mos)
	@echo " ** Simulate QHP  original C/C++   ** "
	(cd QHP && ../$(OMC) +showErrorMessages +d=failtrace simulate.mos > debug-trace.txt 2>&1)

QHP:
	@echo " ** Simulate QHP  original C/C++   ** "
	#(cd QHP && ../$(OMC) +showErrorMessages +d=perfTimes,failtrace simulate.mos > debug-trace-C.txt 2>&1)
	(cd QHP && ../$(OMC) +showErrorMessages +d=perfTimes simulate.mos > debug-trace-C.txt 2>&1)
	@echo " ** Generate QHP CSharp target ** "
	#,failtrace
	(cd QHP && ../$(OMC) +showErrorMessages +d=perfTimes,CSharp generate.mos > debug-trace-CSharp.txt 2>&1)
	

csCopy:
	#(cp -pf ./QHP/Conlon_circulatoryVAD.cs  "/d/Modelica/_svn_Solvers/Compiled Solvers/Simulation/ModelsDotNet/")
	#(cp -pf ./QHP/QHP_Blood_BlooodVolume_ExpandableConnectorPatch_T.cs  "/d/Modelica/_svn_Solvers/Compiled Solvers/Simulation/ModelsDotNet/")
	#(cp -pf ./QHP/QHP_Electrolytes_ExpandableConnectorPatch_T.cs  "/d/Modelica/_svn_Solvers/Compiled Solvers/Simulation/ModelsDotNet/")
	#(cp -pf ./QHP/QHP_test_TestRedCells.cs  "/d/Modelica/_svn_Solvers/Compiled Solvers/Simulation/ModelsDotNet/")
	(cp -pf TrapezUnderground/*.cs  $(ModelsNET))
	(cp -pf RightHeartStarling/*.cs $(ModelsNET))
	(cp -pf ./QHP/*.cs  $(ModelsNET))
	
#RightHeartStarling/RightHeartStarling.cpp :  RightHeartStarling/RightHeartStarling.mo 
#	@echo " ** Generate RightHeartStarling original cpps  ** "
#	(cd RightHeartStarling && ../$(OMC) +d=no_tplmode generate.mos)
 