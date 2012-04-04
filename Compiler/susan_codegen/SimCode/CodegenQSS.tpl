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

package CodegenQSS

import interface SimCodeTV;
import CodegenC.*;

template translateModel(SimCode simCode,QSSinfo qssInfo) 
 "Generates C code and Makefile for compiling and running a simulation of a
  Modelica model."
::=
match simCode
case SIMCODE(modelInfo=modelInfo as MODELINFO(__)) then
  let guid = getUUIDStr()
  let()= textFile(generateQsmModel(simCode,guid,qssInfo), 'model.umo')
  if simulationSettingsOpt then //tests the Option<> for SOME()
     let()= textFile(simulationInitFile(simCode,guid), 'model_init.xml')
     "" //empty result for true case 
  //else "" //the else is automatically empty, too
  //this top-level template always returns an empty result 
  //since generated texts are written to files directly
end translateModel;

template generateQsmModel(SimCode simCode, String guid, QSSinfo qssInfo)
 "Generates a QSM model for simulation ."
::=
match simCode
case SIMCODE(__) then
  <<
  <% generateModelInfo(modelInfo) %>
  <% generateAnnotation(simulationSettingsOpt) %>
  equation 
    <% odeEquations |> eq => generateOdeEqs(eq,BackendQSS.getStateIndexList(qssInfo),BackendQSS.getStates(qssInfo));separator="\n" %>
  end <% getName(modelInfo) %>;

  >>
end generateQsmModel;

template getName(ModelInfo modelInfo)
 "Returns the name of the model"
::=
match modelInfo
case MODELINFO(__) then
  << 
  <%dotPath(name) %>
  >>
end getName;

template generateModelInfo(ModelInfo modelInfo)
 "Generates the first part a QSM model for simulation ."
::=
match modelInfo
case MODELINFO(varInfo=varInfo as  VARINFO(__), name=name as IDENT(__)) then
  <<
  model <% getName(modelInfo) %> 
    constant Integer N = <%varInfo.numStateVars%>;
    Real x[N](start=xinit());
    //Real d[<%varInfo.numIntAlgVars%>];
    //Real a[<%varInfo.numAlgVars%>];
    <% generateInitFunction() %>
  >>
end generateModelInfo;



template generateInitFunction()
 "Generates the initial functions(s)"
::=
<<
  function xinit()
    output Real x[N];
  algorithm
    x(1):=0;
    x(2):=0;
    x(3):=0;
    x(4):=0;
  end xinit;
>>
end generateInitFunction;

template generateAnnotation(Option<SimCode.SimulationSettings> simulationSettingsOpt)
 "Generates the simulation annotation for simulation ."
::=
match simulationSettingsOpt
case SOME(s as SIMULATION_SETTINGS(__)) then
  <<
  annotation(experiment(StartTime = <%s.startTime%>, StopTime = <%s.stopTime%>, Tolerance = <%s.tolerance%>, Solver = <%s.method%>, OutputFormat = <%s.outputFormat%>, VariableFilter = <%s.variableFilter%>));
  >>
end generateAnnotation;

template generateOdeEqs(list<SimEqSystem> odeEquations,list<list<Integer>> indexs, list<DAE.ComponentRef> states)
 "Generates the ODE equations of the model"
::=
<<
<% (odeEquations |> eq hasindex i0 => generateOdeEq(eq,listNth(indexs,i0),states); separator="\n")  %>
>>
end generateOdeEqs;

template generateOdeEq(SimEqSystem odeEquation,list<Integer> indexEq, list<DAE.ComponentRef> states)
 "Generates one  ODE equation of the model"
::=
match odeEquation
case SES_SIMPLE_ASSIGN(__) then 
<<
  der(x[<% indexEq %>]) = <% ExpressionDump.printExpStr(BackendQSS.replaceVars(exp,states)) %>;
>>
end generateOdeEq;



end CodegenQSS;
