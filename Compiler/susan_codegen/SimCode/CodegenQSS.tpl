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
  let()= textFile(generateQsmModel(simCode,qssInfo), 'model.mo')
  ""
end translateModel;

template generateQsmModel(SimCode simCode, QSSinfo qssInfo)
 "Generates a QSM model for simulation ."
::=
match simCode
case SIMCODE(__) then
  <<
  <% generateModelInfo(modelInfo,BackendQSS.getStates(qssInfo),BackendQSS.getDisc(qssInfo),BackendQSS.getAlgs(qssInfo)) %>
  <% generateAnnotation(simulationSettingsOpt) %>
  equation 
    <% odeEquations |> eq => generateOdeEqs(eq,BackendQSS.getStateIndexList(qssInfo),BackendQSS.getStates(qssInfo),BackendQSS.getDisc(qssInfo),BackendQSS.getAlgs(qssInfo));separator="\n" %>
  algorithm
  <% generateDiscont(zeroCrossings,BackendQSS.getStates(qssInfo),BackendQSS.getDisc(qssInfo),BackendQSS.getAlgs(qssInfo),
                     whenClauses,allEquations) %>
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

template generateModelInfo(ModelInfo modelInfo,  list<DAE.ComponentRef> states, list<DAE.ComponentRef> disc, list<DAE.ComponentRef> algs)
 "Generates the first part a QSM model for simulation ."
::=
match modelInfo
case MODELINFO(varInfo=varInfo as  VARINFO(__), name=name as IDENT(__)) then
  <<
  model <% getName(modelInfo) %> 
    constant Integer N = <%varInfo.numStateVars%>;
    Real x[N](start=xinit());
    discrete Real d[<% intAdd(varInfo.numIntAlgVars,varInfo.numBoolAlgVars) %>](start=dinit());
    Real a[<% varInfo.numAlgVars %>](start=ainit()); 
    <% generateExtraVars(modelInfo) %>
    <% generateInitFunction(modelInfo,states,disc,algs) %>
  >>
end generateModelInfo;

template OptionInitial(Option<DAE.Exp> initialValue)
 "generates code for start attribute"
::=
match initialValue
  case SOME(DAE.BCONST(bool=true)) then '1.0'
  case SOME(DAE.BCONST(bool=false)) then '0.0'
  case SOME(exp) then '<%initValXml(exp)%>' 
  case NONE() then '0.0'
end OptionInitial;

template InitStateVariable(SimVar simVar, list<DAE.ComponentRef> vars)
 "Generates code for ScalarVariable file for FMU target."
::=
  match simVar
  case SIMVAR(__) then
  <<
  x[<% intAdd(List.position(name,vars),1) %>]:= <% OptionInitial(initialValue) %> /* <% crefStr(name) %> */;
  >>

end InitStateVariable;

template InitAlgVariable(SimVar simVar, list<DAE.ComponentRef> vars)
 "Generates code for ScalarVariable file for FMU target."
::=
  match simVar
  case SIMVAR(__) then
  <<
  a[<% intAdd(List.position(name,vars),1) %>]:= <% OptionInitial(initialValue) %> /* <% crefStr(name) %> */;
  >>
end InitAlgVariable;

template InitDiscVariable(SimVar simVar, list<DAE.ComponentRef> vars)
 "Generates code for ScalarVariable file for FMU target."
::=
  match simVar
  case SIMVAR(__) then
  <<
  d[<% intAdd(List.position(name,vars),1) %>]:= <% OptionInitial(initialValue) %> /* <% crefStr(name) %> */;
  >>
end InitDiscVariable;



template generateVarDefinition(SimVar var)
 "Generates the code for extra variables"
::=
match var
case SIMVAR(__) then
  <<
  parameter Real <% System.stringReplace(crefStr(name),".", "_") %> = <% OptionInitial(initialValue) %>;
  >>
end generateVarDefinition;

template generateExtraVars(ModelInfo modelInfo)
 "Generates the code for extra variables"
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<
  <% vars.paramVars |> v => generateVarDefinition(v);separator="\n" %>
  <% vars.intParamVars |> v => generateVarDefinition(v);separator="\n" %>
  <% vars.boolParamVars |> v => generateVarDefinition(v);separator="\n" %>
  >>
end generateExtraVars;

template generateInitFunction(ModelInfo modelInfo, list<DAE.ComponentRef> states, list<DAE.ComponentRef> disc, list<DAE.ComponentRef> algs)
 "Generates the initial functions(s)"
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<
  function xinit
    output Real x[N];
  algorithm
    <% vars.stateVars |> var hasindex i0 => InitStateVariable(var,states);separator="\n"%>
  end xinit;
  function dinit
    output Real d[<% intAdd(listLength(vars.intAlgVars),listLength(vars.boolAlgVars)) %>];
  algorithm
    <%vars.intAlgVars |> var hasindex i0 => InitDiscVariable(var,disc);separator="\n"%>
    <%vars.boolAlgVars |> var hasindex i0 => InitDiscVariable(var,disc);separator="\n"%>
  end dinit;
  function ainit
    output Real a[<% listLength(vars.algVars) %>];
  algorithm
    <%vars.algVars |> var hasindex i0 => InitAlgVariable(var,algs);separator="\n"%>
  end ainit;
 
 
  >>
end generateInitFunction;

template generateAnnotation(Option<SimCode.SimulationSettings> simulationSettingsOpt)
 "Generates the simulation annotation for simulation ."
::=
match simulationSettingsOpt
case SOME(s as SIMULATION_SETTINGS(__)) then
  <<
    annotation(experiment(StartTime = <%s.startTime%>, StopTime = <%s.stopTime%>, Tolerance = <%s.tolerance%>, AbsTolerance = <%s.tolerance %>, Solver = QSS3, Output = {x[1]},  OutputFormat = <%s.outputFormat%>, VariableFilter = "<%s.variableFilter%>"));
  >>
end generateAnnotation;

template generateOdeEqs(list<SimEqSystem> odeEquations,list<list<Integer>> indexs, list<DAE.ComponentRef> states,list<DAE.ComponentRef> disc,list<DAE.ComponentRef> algs)
 "Generates the ODE equations of the model"
::=
<<
<% (odeEquations |> eq hasindex i0 => generateOdeEq(eq,listNth(indexs,0),states,disc,algs); separator="\n")  %>
>>
end generateOdeEqs;

template generateAlgorithm(SimEqSystem algEquation, list<DAE.ComponentRef> states, list<DAE.ComponentRef> disc, list<DAE.ComponentRef> algs)
 "Generates one algorithm equation of the model"
::=
match algEquation
case SES_ALGORITHM(statements={DAE.STMT_WHEN(exp=exp)}) then 
<<
  when <% ExpressionDump.printExpStr(BackendQSS.replaceVars(exp,states,disc,algs)) %> then
    blahh;
  end when;
>>
  else
    "NOT IMPLEMENTED EQUATION"
end generateAlgorithm;

template generateOdeEq(SimEqSystem odeEquation,list<Integer> indexEq, list<DAE.ComponentRef> states, list<DAE.ComponentRef> disc, list<DAE.ComponentRef> algs)
 "Generates one  ODE equation of the model
  der(x[ indexEq ]) = "
::=
match odeEquation
case SES_SIMPLE_ASSIGN(__) then 
  <<
  <% BackendQSS.replaceCref(cref,states,disc,algs) %> = <% ExpressionDump.printExpStr(BackendQSS.replaceVars(exp,states,disc,algs)) %>;
  >>
end generateOdeEq;

template generateZC(list<BackendDAE.ZeroCrossing> zcs, list<DAE.ComponentRef> states, 
                    list<DAE.ComponentRef> disc, list<DAE.ComponentRef> algs, list<SimCode.SimWhenClause> whens, list<SimCode.SimEqSystem> eqs)
 "Generates one zc equation of the model"
::=
  <<
  <% (zcs |> zc => generateOneZC(zc,states,disc,algs,eqs);separator="\n") %>
  >>
end generateZC;

template generateAssigment(SimCode.SimEqSystem eq,list<DAE.ComponentRef> states,
                    list<DAE.ComponentRef> disc, list<DAE.ComponentRef> algs)
"gnereates an assigment"
::=
  match eq
  case SimCode.SES_SIMPLE_ASSIGN(__) then
<<
  <% BackendQSS.replaceCref(cref,states,disc,algs) %> = <% ExpressionDump.printExpStr(BackendQSS.replaceVars(exp,states,disc,algs)) %>;
>>
end generateAssigment;

template generateOneZC(BackendDAE.ZeroCrossing zc,list<DAE.ComponentRef> states,
                    list<DAE.ComponentRef> disc, list<DAE.ComponentRef> algs, list<SimCode.SimEqSystem> eqs)
"generates one "
::=
  match zc
  case BackendDAE.ZERO_CROSSING(__) then
<<
  when <% ExpressionDump.printExpStr(BackendQSS.replaceVars(relation_,states,disc,algs)) %> then
    /* In Eq <% listNth(occurEquLst,0) %> out of <% listLength(occurEquLst) %> */
    <% generateAssigment(listNth(eqs,listNth(occurEquLst,0)),states,disc,algs) %>
    
  end when;
>>
end generateOneZC;

/*
template generateWhen(SimCode.SimWhenClause when, list<DAE.ComponentRef> states, list<DAE.ComponentRef> disc, list<DAE.ComponentRef> algs)
::=
match when
case SIM_WHEN_CLAUSE(conditions=conditions,whenEq= SOME(WHEN_EQ(left=left,right=right,elsewhenPart=NONE()))) then
  <<
  when <% generateCond(conditions,states,disc) %> then 
    d[<% intAdd(List.position(left,disc),1) %>] := <% ExpressionDump.printExpStr(BackendQSS.replaceVars(right,states,disc,algs)) %>;
  end when;
  >>
case SIM_WHEN_CLAUSE(whenEq= SOME(WHEN_EQ(left=left,right=right,elsewhenPart=SOME(WHEN_EQ(left=left_w,right=right_w))))) then 
  <<
  when <% generateCond(conditions,states,disc) %> then 
    d[<% intAdd(List.position(left,disc),1) %>] := <% ExpressionDump.printExpStr(BackendQSS.replaceVars(right,states,disc,algs)) %>;
  end when;
  >>
else
  <<
    NOT MATCHED WHEN
  >>
end generateWhen;
*/

template generateCond(list<tuple<DAE.Exp, Integer>> conds, list<DAE.ComponentRef> states, list<DAE.ComponentRef> disc,list<DAE.ComponentRef> algs)
::=
  match conds
  case ({(e,_)}) then
  <<
  <% ExpressionDump.printExpStr(BackendQSS.replaceVars(e,states,disc,algs)) %>
  >>
  else 'initial()'
end generateCond;

template generateDiscont(list<BackendDAE.ZeroCrossing> zcs, list<DAE.ComponentRef> states,
                    list<DAE.ComponentRef> disc, list<DAE.ComponentRef> algs, list<SimCode.SimWhenClause> whens, list<SimCode.SimEqSystem> eqs)
::=
  <<
  /* Got <% listLength(eqs) %> equations */
  <% generateZC(zcs,states,disc,algs,whens,eqs) %>
  >>
end generateDiscont;

end CodegenQSS;
