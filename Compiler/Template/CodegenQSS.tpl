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
import interface SimCodeQSSTV;
import CodegenUtil.*;
import CodegenCFunctions.*;

template translateModel(SimCode simCode,QSSinfo qssInfo)
 "Generates C code and Makefile for compiling and running a simulation of a
  Modelica model."
::=
match simCode
case SIMCODE(modelInfo=modelInfo as MODELINFO(__)) then
  let()= textFile(generateQsmModel(simCode,qssInfo), '<% getName(modelInfo) %>.mo')
  let()= textFile(generateMakefile(getName(modelInfo)), '<% getName(modelInfo) %>.makefile')
  ""
end translateModel;

template generateQsmModel(SimCode simCode, QSSinfo qssInfo)
 "Generates a QSM model for simulation ."
::=
match simCode
case SIMCODE(__) then
  let &funDecls = buffer "" /*BUFD*/
  let &externalFuncs = buffer '#include <gsl/gsl_math.h>
#include <gsl/gsl_blas.h>
#include <gsl/gsl_vector.h>
#include <gsl/gsl_matrix.h>
#include <gsl/gsl_linalg.h>
#include "<% getName(modelInfo)%>_parameters.h" // Parameters
' /*BUFD*/
  let eqs = (odeEquations |> eq => generateOdeEqs(eq, BackendQSS.getStateIndexList(qssInfo), BackendQSS.getStates(qssInfo), BackendQSS.getDisc(qssInfo), BackendQSS.getAlgs(qssInfo), &funDecls, externalFuncs); separator="\n")
  let () = textFile(&externalFuncs,'<% getName(modelInfo)%>_external_functions.c')
  <<
  <% generateModelInfo(modelInfo,BackendQSS.getStates(qssInfo),BackendQSS.getDisc(qssInfo),BackendQSS.getAlgs(qssInfo),parameterEquations) %>
  <% funDecls %>

  <% generateAnnotation(simulationSettingsOpt) %>

  /* Equations */
  equation
  <% eqs %>
  algorithm
  /* Discontinuities(<% listLength(zeroCrossings) %>) */
  <% generateDiscont(zeroCrossings,BackendQSS.getStates(qssInfo),BackendQSS.getDisc(qssInfo),BackendQSS.getAlgs(qssInfo),
                     whenClauses,BackendQSS.getEqs(qssInfo),0,BackendQSS.getZCExps(qssInfo), BackendQSS.getZCOffset(qssInfo)) %>
  end <% getName(modelInfo) %>;
  >>
end generateQsmModel;

template getName(ModelInfo modelInfo)
 "Returns the name of the model"
::=
match modelInfo
case MODELINFO(__) then
  <<
  <%System.stringReplace(dotPath(name),".","_") %>
  >>
end getName;

template generateModelInfo(ModelInfo modelInfo,  list<DAE.ComponentRef> states,
                      list<DAE.ComponentRef> disc, list<DAE.ComponentRef> algs,
                      list<SimEqSystem> parameterEquations)
 "Generates the first part a QSM model for simulation ."
::=
match modelInfo
case MODELINFO(varInfo=varInfo as  VARINFO(__)) then
  <<
  model <% getName(modelInfo) %>

    <% generateInitFunction(modelInfo,states,disc,algs) %>

    /* Parameters */
    <% generateParameters(modelInfo,parameterEquations) %>

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
  Real <% crefStr(name) %> (start = <% OptionInitial(initialValue) %>);
  >>

end InitStateVariable;

template InitAlgVariable(SimVar simVar, list<DAE.ComponentRef> vars)
 "Generates code for ScalarVariable file for FMU target."
::=
  match simVar
  case SIMVAR(__) then
  <<
  Real <% crefStr(name) %>;
  >>
end InitAlgVariable;

template InitDiscVariable(DAE.ComponentRef var)
::=
  <<
  0.0
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

template generateParameters(ModelInfo modelInfo,list<SimEqSystem> parameterEquations)
 "Generates the code for extra variables"
::=
match modelInfo
case MODELINFO(vars=vars as SIMVARS(__)) then
let () = textFile(generateHeader(modelInfo,parameterEquations),'<% getName(modelInfo) %>_parameters.h')
  <<
  <% vars.paramVars |> v => generateVarDefinition(v);separator="\n" %>
  <% vars.intParamVars |> v => generateVarDefinition(v);separator="\n" %>
  <% vars.boolParamVars |> v => generateVarDefinition(v);separator="\n" %>
  <% parameterEquations |> eq => BackendQSS.generateExtraParams(eq,vars);separator="\n" %>
  >>
end generateParameters;

template generateInitFunction(ModelInfo modelInfo, list<DAE.ComponentRef> states, list<DAE.ComponentRef> disc, list<DAE.ComponentRef> algs)
 "Generates the initial functions(s)"
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<

  /* States */
  <% vars.stateVars |> var hasindex i0 => InitStateVariable(var,states);separator="\n"%>

  /* Algebraics */
  <% vars.algVars |> var hasindex i0 => InitAlgVariable(var,algs);separator="\n"%>

  /* Discrete Algebraics */
  <% vars.discreteAlgVars |> var hasindex i0 => InitAlgVariable(var,algs);separator="\n"%>

  /* Discretes */
  discrete Real d[<% listLength(disc) %>](start=dinit());

  function boolToReal
    input Boolean b;
    output Real r;
  algorithm
    r:=if b then 1.0 else 0.0;
  end boolToReal;

  function dinit
    output Real d[<% listLength(disc) %>];
  algorithm
    <% BackendQSS.generateDInit(disc,vars,0,listLength(disc),1) %>
  end dinit;
  >>
end generateInitFunction;

template generateAnnotation(Option<SimCode.SimulationSettings> simulationSettingsOpt)
 "Generates the simulation annotation for simulation ."
::=
match simulationSettingsOpt
case SOME(s as SIMULATION_SETTINGS(__)) then
  <<
    annotation(experiment(StartTime = <%s.startTime%>, StopTime = <%s.stopTime%>, Tolerance = 1e-3, AbsTolerance = 1e-3, Solver = LIQSS2, StepSize = <%s.stopTime%>/500));
  >>
end generateAnnotation;

template generateOdeEqs(list<SimEqSystem> odeEquations, list<list<Integer>> indexs, list<DAE.ComponentRef> states, list<DAE.ComponentRef> disc, list<DAE.ComponentRef> algs, Text &funDecls, Text &externalFuncs)
 "Generates the ODE equations of the model"
::=
  <<
  <% (odeEquations |> eq hasindex i0 => generateOdeEq(eq, states, disc, algs, &funDecls, &externalFuncs); separator="\n") %>
  >>
end generateOdeEqs;

template generateOdeEq(SimEqSystem odeEquation, list<DAE.ComponentRef> states, list<DAE.ComponentRef> disc, list<DAE.ComponentRef> algs, Text &funDecls, Text &externalFuncs)
 "Generates one  ODE equation of the model"
::=
match odeEquation
case SES_SIMPLE_ASSIGN(__) then
<<
  <%System.stringReplace(crefStr(cref),".", "_")%> = <%  ExpressionDump.printExpStr(BackendQSS.replaceVars(exp,states,disc,algs)) %>;
>>

case e as SES_LINEAR(lSystem=ls as LINEARSYSTEM(__)) then
  let out_vars = (ls.vars |> v => match v case SIMVAR(name=name) then BackendQSS.replaceCref(name,states,disc,algs);separator=",")
  let in_vars =  (BackendQSS.getRHSVars(ls.beqs,ls.vars,ls.simJac,states,disc,algs) |> cref =>
       BackendQSS.replaceCref(cref,states,disc,algs);separator="," )
  let &externalFuncs += generateLinear(e,states,disc,algs)
  let &funDecls +=
<<

  function fsolve<%ls.index%>
    <% BackendQSS.getRHSVars(ls.beqs,ls.vars,ls.simJac,states,disc,algs) |> v hasindex i0 => 'input Real i<%i0%>;' ;separator="\n" %>
    <% ls.vars |> v hasindex i0 => 'output Real o<%i0%>;' ;separator="\n" %>
  external "C" ;
  end fsolve<%ls.index%>;

>>
<<
  (<% out_vars %>)=fsolve<%ls.index%>(<% in_vars %>);
>>

case SES_RESIDUAL(__) then
<<
  /* Residual */
>>
case SES_ARRAY_CALL_ASSIGN(__) then
<<
  /* Array */
>>
case SES_NONLINEAR(__) then
<<
  /* Non linear */
>>
case SES_MIXED(__) then
<<
  /* Mixed */
>>
case SES_WHEN(__) then
<<
  /* When */
>>
case SES_ALGORITHM(__) then
<<
>>
else
<<
>>
end generateOdeEq;

template generateZC(list<BackendDAE.ZeroCrossing> zcs, list<DAE.ComponentRef> states,
                    list<DAE.ComponentRef> disc, list<DAE.ComponentRef> algs,
                    BackendDAE.EquationArray eqs,list<DAE.Exp> zc_exps, Integer offset)
 "Generates one zc equation of the model"
::=
  <<
  <% (zcs |> zc => generateOneZC(zc,states,disc,algs,eqs,zc_exps,offset);separator="\n") %>
  >>
end generateZC;

template generateAssigment(BackendDAE.EqSystem eq,list<DAE.ComponentRef> states,
                    list<DAE.ComponentRef> disc, list<DAE.ComponentRef> algs)
"gnereates an assigment"
::=
<<
>>
end generateAssigment;

template generateOneZC(BackendDAE.ZeroCrossing zc,list<DAE.ComponentRef> states,
                    list<DAE.ComponentRef> disc, list<DAE.ComponentRef> algs, BackendDAE.EquationArray eqs,
                    list<DAE.Exp> zc_exps, Integer offset)
"generates one "
::=
  match zc
  case BackendDAE.ZERO_CROSSING(__) then
<<
  when <% ExpressionDump.printExpStr(BackendQSS.replaceVars(relation_,states,disc,algs)) %> then
     <% BackendQSS.generateHandler(eqs,occurEquLst,states,disc,algs,relation_,true,zc_exps,offset) %>
  elsewhen <% ExpressionDump.printExpStr(BackendQSS.replaceVars(BackendQSS.negate(relation_),states,disc,algs)) %>  then
     <% BackendQSS.generateHandler(eqs,occurEquLst,states,disc,algs,relation_,false,zc_exps,offset) %>
  end when;
>>
  else
  <<
  /*  NOT MATCHED ZC */
  >>
end generateOneZC;

template generateWhen(SimCode.SimWhenClause when, list<DAE.ComponentRef> states, list<DAE.ComponentRef> disc, list<DAE.ComponentRef> algs, Integer index)
::=
match when
case SIM_WHEN_CLAUSE(conditions=conditions, initialCall=initialCall, whenEq=SOME(WHEN_EQ(left=left, right=right, elsewhenPart=NONE()))) then
let &extraCode = buffer "" /*BUFD*/
<<
  /* When <% index %> */
  when <% generateCond(conditions, states, disc, algs, extraCode, index) %> then
   <% BackendQSS.replaceCref(left,states,disc,algs) %> := <% ExpressionDump.printExpStr(BackendQSS.replaceVars(right,states,disc,algs)) %>;
   <% extraCode %>
  end when;
>>
case SIM_WHEN_CLAUSE(conditions=conditions, initialCall=initialCall, whenEq=SOME(WHEN_EQ(left=left, right=right, elsewhenPart=SOME(__)))) then
let &extraCode = buffer "" /*BUFD*/
<<
  /* When <% index %> */
  when <% generateCond(conditions, states, disc, algs, extraCode, index) %> then
    <% BackendQSS.replaceCref(left,states,disc,algs) %> := <% ExpressionDump.printExpStr(BackendQSS.replaceVars(right,states,disc,algs)) %>;
    <% extraCode %>
  end when;
>>
/*
case SIM_WHEN_CLAUSE(conditions=conditions,whenEq= SOME(WHEN_EQ(left=left,right=right,elsewhenPart=NONE()))) then
let &extraCode = buffer "" /*BUFD*/
(conditions |> cond => <<
  when <% generateCond(cond, states, disc, algs, extraCode, index) %> then
    <% BackendQSS.replaceCref(left,states,disc,algs) %> := <% ExpressionDump.printExpStr(BackendQSS.replaceVars(right,states,disc,algs)) %>;
    <% extraCode %>
  end when;
>>; separator="\n")
*/
else
  <<
  /*  NOT MATCHED WHEN */
  >>
end generateWhen;

template generateCond(list<DAE.ComponentRef> conds, list<DAE.ComponentRef> states,
                      list<DAE.ComponentRef> disc,list<DAE.ComponentRef> algs,Text &extraCode, Integer index)
::=
  match (conds)
    case ({e}) then
      <<
      <% BackendQSS.replaceCref(e,states,disc,algs) %> > 0.5
      >>
end generateCond;

template generateDiscont(list<BackendDAE.ZeroCrossing> zcs, list<DAE.ComponentRef> states,
  list<DAE.ComponentRef> disc, list<DAE.ComponentRef> algs, list<SimCode.SimWhenClause> whens,BackendDAE.EquationArray eqs,
  Integer nSamples,list<DAE.Exp> zc_exps, Integer offset)
::=
  <<
  <% generateZC(zcs,states,disc,algs,eqs,zc_exps,offset) %>
  <% BackendQSS.simpleWhens(whens) |> w hasindex i0 => generateWhen(w,states,disc,algs,0);separator="\n" %>
  <% BackendQSS.sampleWhens(whens) |> w hasindex i0 =>
    generateWhen(w,states,disc,algs,intAdd(i0,intSub(listLength(disc),nSamples)));separator="\n" %>
  >>
end generateDiscont;

template generateLinear(SimEqSystem eq,list<DAE.ComponentRef> states, list<DAE.ComponentRef> disc, list<DAE.ComponentRef> algs)
::=
match eq
case SES_LINEAR(lSystem=ls as LINEARSYSTEM(__)) then
let &preExp = buffer "" /*BUFD*/
let &varDecls = buffer "" /*BUFD*/
let &auxFunctionIgnore = buffer ""
<<

gsl_matrix *A<%ls.index%>,*invA<%ls.index%>;
gsl_vector *b<%ls.index%>,*x<%ls.index%>;
gsl_permutation *p<%ls.index%>;
int init<%ls.index%> = 0;
<% (BackendQSS.getDiscRHSVars(ls.beqs,ls.vars,ls.simJac,states,disc,algs) |> v hasindex i0 =>
  let i=List.position(v,BackendQSS.getRHSVars(ls.beqs,ls.vars,ls.simJac,states,disc,algs))
  'double old_i<%i%>_<%ls.index%>=-1;';separator="\n") %>

void fsolve<%ls.index%>(<%
(BackendQSS.getRHSVars(ls.beqs,ls.vars,ls.simJac,states,disc,algs) |> v hasindex i0 => 'double i<%i0%>';separator=",")
%>,<%ls.vars |> SIMVAR(__) hasindex i0 => 'double *o<%i0%>' ;separator=","%>)
{
  const int DIM = <% listLength(ls.beqs) %>;
  int invert_matrix = 0;
  int signum;

  invert_matrix = 0;

  <%
  (BackendQSS.getDiscRHSVars(ls.beqs,ls.vars,ls.simJac,states,disc,algs) |> v hasindex i0 =>
  let i=List.position(v,BackendQSS.getRHSVars(ls.beqs,ls.vars,ls.simJac,states,disc,algs))
  'if (old_i<%i%>_<%ls.index%>!=i<%i%>) {
    invert_matrix=1;
    old_i<%i%>_<%ls.index%>=i<%i%>;
}';separator="\n") %>

  if (!init<%ls.index%>) {
    /* Alloc space */
    A<%ls.index%> = gsl_matrix_alloc(DIM, DIM);
    invA<%ls.index%> = gsl_matrix_alloc(DIM, DIM);
    b<%ls.index%> = gsl_vector_alloc(DIM);
    x<%ls.index%> = gsl_vector_alloc(DIM);
    p<%ls.index%> = gsl_permutation_alloc(DIM);
    init<%ls.index%>=1;
    invert_matrix=1;
  }

  /* Fill B */
  <%ls.beqs |> exp hasindex i0 =>
    'gsl_vector_set(b<%ls.index%>,<%i0%>,<%
      System.stringReplace(daeExp(
        BackendQSS.replaceVarsInputs(exp,BackendQSS.getRHSVars(ls.beqs,ls.vars,ls.simJac,states,disc,algs)),
        contextOther,&preExp,&varDecls,&auxFunctionIgnore),"$P","") %>);';separator=\n%>

  /* Invert matrix if necesary */
  if (invert_matrix)
  {
    /* Fill A */
    gsl_matrix_set_zero(A<%ls.index%>);
    <%ls.simJac |> (row, col, eq as SES_RESIDUAL(__)) =>
     'gsl_matrix_set(A<%ls.index%>, <%row%>, <%col%>,<%  System.stringReplace(daeExp(
        BackendQSS.replaceVarsInputs(eq.exp,BackendQSS.getRHSVars(ls.beqs,ls.vars,ls.simJac,states,disc,algs)),
        contextOther,&preExp,&varDecls,&auxFunctionIgnore),"$P","") %>);'
    ;separator="\n"%>
    gsl_linalg_LU_decomp(A<%ls.index%>, p<%ls.index%>, &signum);
    gsl_linalg_LU_invert(A<%ls.index%>, p<%ls.index%> ,invA<%ls.index%>);
  }

  /* Copmute x=inv(A)*b */
  gsl_blas_dgemv(CblasNoTrans,1.0,invA<%ls.index%>,b<%ls.index%>,0.0,x<%ls.index%>);
  /* Get x values out */
  <%ls.vars |> v hasindex i0 => '*o<%i0%> = gsl_vector_get(x<%ls.index%>, <%i0%>);' ;separator="\n"%>
}

>>
end generateLinear;

template generateHeader(ModelInfo modelInfo,list<SimEqSystem> parameterEquations)
::=
match modelInfo
case MODELINFO(vars=vars as SIMVARS(__)) then
<<
<% vars.paramVars |> v => match v case SIMVAR(__) then 'extern double <%System.stringReplace(crefStr(name),".", "_")%>;'
  ;separator="\n" %>
<% vars.intParamVars |> v => match v case SIMVAR(__) then 'extern double <%System.stringReplace(crefStr(name),".", "_")%>;'
  ;separator="\n" %>
<% vars.boolParamVars |> v => match v case SIMVAR(__) then 'extern double <%System.stringReplace(crefStr(name),".", "_")%>;'
  ;separator="\n" %>
>>
end generateHeader;

template generateMakefile(String name)
 "Generates a QSM model for simulation ."
::=
<<
all: <%name%>.mo <%name%>_parameters.h <%name%>_external_functions.c
<%\t%>mo2qsm ./<%name%>.mo
<%\t%>qssmg  ./<%name%>.qsm $(QSSPATH)
<%\t%>make
<%\t%>./<%name%>
<%\t%>echo "set terminal wxt persist; set grid; plot \"<%name%>_x0.dat\" with lines " | gnuplot
>>
end generateMakefile;

annotation(__OpenModelica_Interface="backend");
end CodegenQSS;
