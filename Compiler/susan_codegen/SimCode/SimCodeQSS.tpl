// This file defines templates for transforming Modelica/MetaModelica code to C++
// code needed to use the QSS solvers for simulation
//
// Authors: Federico Bergero & Xenofon Floros
// April 2011
// This file defines templates for transforming Modelica/MetaModelica code to C
// code. They are used in the code generator phase of the compiler to write
// target code.
//
// There are two root templates intended to be called from the code generator:
// translateModel and translateFunctions. These templates do not return any
// result but instead write the result to files. All other templates return
// text and are used by the root templates (most of them indirectly).
//
// To future maintainers of this file:
//
// - A line like this
//     # var = "" /*BUFD*/
//   declares a text buffer that you can later append text to. It can also be
//   passed to other templates that in turn can append text to it. In the new
//   version of Susan it should be written like this instead:
//     let &var = buffer ""
//
// - A line like this
//     ..., Text var /*BUFP*/, ...
//   declares that a template takes a text buffer as input parameter. In the
//   new version of Susan it should be written like this instead:
//     ..., Text &var, ...
//
// - A line like this:
//     ..., var /*BUFC*/, ...
//   passes a text buffer to a template. In the new version of Susan it should
//   be written like this instead:
//     ..., &var, ...
//
// - Style guidelines:
//
//   - Try (hard) to limit each row to 80 characters
//
//   - Code for a template should be indented with 2 spaces
//
//     - Exception to this rule is if you have only a single case, then that
//       single case can be written using no indentation
//
//       This single case can be seen as a clarification of the input to the
//       template
//
//   - Code after a case should be indented with 2 spaces if not written on the
//     same line

package SimCodeQSS

import interface SimCodeTV;
import SimCodeC;

template translateModel(SimCode simCode) 
 "Generates C code and Makefile for compiling and running a simulation of a
  Modelica model."
::=
match simCode
case SIMCODE(modelInfo=modelInfo as MODELINFO(__)) then
  let()= textFile(simulationFile(simCode), '<%fileNamePrefix%>.cpp')
  let()= textFile(SimCodeC.simulationFunctionsHeaderFile(fileNamePrefix, modelInfo.functions, recordDecls), '<%fileNamePrefix%>_functions.h')
  let()= textFile(SimCodeC.simulationFunctionsFile(fileNamePrefix, modelInfo.functions, literals), '<%fileNamePrefix%>_functions.cpp')
  let()= textFile(SimCodeC.recordsFile(fileNamePrefix, recordDecls), '<%fileNamePrefix%>_records.c')
  let()= textFile(SimCodeC.simulationMakefile(simCode), '<%fileNamePrefix%>.makefile')
  if simulationSettingsOpt then //tests the Option<> for SOME()
     let()= textFile(SimCodeC.simulationInitFile(simCode), '<%fileNamePrefix%>_init.txt')
     "" //empty result for true case 
  //else "" //the else is automatically empty, too
  //this top-level template always returns an empty result 
  //since generated texts are written to files directly
end translateModel;

template simulationFile(SimCode simCode)
 "Generates code for main C file for simulation target."
::=
match simCode
case SIMCODE(__) then
  <<

  <%SimCodeC.simulationFileHeader(simCode)%>

  <%SimCodeC.externalFunctionIncludes(externalFunctionIncludes)%>

  #ifdef _OMC_MEASURE_TIME
  int measure_time_flag = 1;
  #else
  int measure_time_flag = 0;
  #endif

  <%SimCodeC.globalData(modelInfo,fileNamePrefix)%>
  
  <%SimCodeC.equationInfo(appendLists(appendAllequation(JacobianMatrixes),allEquations))%>
  
  <%SimCodeC.functionGetName(modelInfo)%>
  
  <%SimCodeC.functionSetLocalData()%>
  
  <%SimCodeC.functionInitializeDataStruc()%>

  <%SimCodeC.functionCallExternalObjectConstructors(extObjInfo)%>
  
  <%SimCodeC.functionDeInitializeDataStruc(extObjInfo)%>
  
  <%SimCodeC.functionExtraResiduals(allEquations)%>
  
  // fbergero, xfloros: Code for QSS methods
  #ifdef _OMC_QSS
  <%functionQssSample(zeroCrossings)%>

  <%functionQssWhen(whenClauses, helpVarInfo)%>
  #endif
  <%\n%> 
  >>
  /* adrpo: leave a newline at the end of file to get rid of the warning */
end simulationFile;

template functionQssSample2(list<ZeroCrossing> zeroCrossings, Text &varDecls /*BUFP*/)
 "Generates code for zero crossings."
::=

  (zeroCrossings |> ZERO_CROSSING(relation_ = CALL(path=IDENT(name="sample"), expLst={start, interval})) hasindex i0 =>
    functionQssSample3(i0, start,interval, &varDecls /*BUFD*/)
  ;separator="\n")
end functionQssSample2;

template functionQssSample3(Integer index1, Exp start, Exp interval, Text &varDecls /*BUFP*/)
 "Generates code for a zero crossing."
::=
    let &preExp = buffer "" /*BUFD*/
    let e1 = SimCodeC.daeExp(start, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let e2 = SimCodeC.daeExp(interval, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    <<
    case <% index1 %>:
      <%preExp%>
      out[0] = <% e1 %>;
      out[1] = <% e2 %>;
      break;
    >>
end functionQssSample3;

template functionQssSample(list<ZeroCrossing> zeroCrossings)
  "Generates function in simulation file."
::=
  let &varDecls = buffer "" /*BUFD*/
  let sampleCode = functionQssSample2(zeroCrossings, &varDecls /*BUFD*/) 
  <<
  void functionQssSample(unsigned int sampleIndex, double *out)
  {
    state mem_state;
    <%varDecls%>
    mem_state = get_memory_state();
    switch (sampleIndex)
    {
      <%sampleCode%>
    }
    restore_memory_state(mem_state);
  }
  >>
end functionQssSample;

template functionQssWhen(list<SimWhenClause> whenClauses, list<HelpVarInfo> helpVars)
  "Generates function in simulation file."
::=
  let &varDecls = buffer "" /*BUFD*/
  <<
  bool functionQssWhen(unsigned int whenIndex, double *out)
  {
    state mem_state;
    <%varDecls%>
    mem_state = get_memory_state();
    switch (whenIndex)
    {
    }
    restore_memory_state(mem_state);
  }
  >>
end functionQssWhen;



end SimCodeQSS;

// vim: filetype=susan sw=2 sts=2
