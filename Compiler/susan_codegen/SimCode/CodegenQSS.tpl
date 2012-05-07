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
  let &externalFuncs = buffer "#include <gsl/gsl_math.h>
#include <gsl/gsl_blas.h>
#include <gsl/gsl_vector.h>
#include <gsl/gsl_matrix.h>
#include <gsl/gsl_linalg.h>
#include \"parameters.h\" // Parameters
" /*BUFD*/
  let eqs = (odeEquations |> eq => generateOdeEqs(eq,BackendQSS.getStateIndexList(qssInfo),BackendQSS.getStates(qssInfo),BackendQSS.getDisc(qssInfo),BackendQSS.getAlgs(qssInfo),&funDecls,externalFuncs);separator="\n")
  let () = textFile(&externalFuncs,'<% getName(modelInfo)%>_external_functions.c')
  <<
  <% generateModelInfo(modelInfo,BackendQSS.getStates(qssInfo),BackendQSS.getDisc(qssInfo),BackendQSS.getAlgs(qssInfo),sampleConditions,parameterEquations) %>
  <% funDecls %>

  <% generateAnnotation(simulationSettingsOpt) %>

  /* Equations */
  equation 
  <% eqs %>
  algorithm
  /* Discontinuities */
  <% generateDiscont(zeroCrossings,BackendQSS.getStates(qssInfo),BackendQSS.getDisc(qssInfo),BackendQSS.getAlgs(qssInfo),
                     whenClauses,BackendQSS.getEqs(qssInfo)) %>
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
                      list<SimCode.SampleCondition> sampleConditions,list<SimEqSystem> parameterEquations)
 "Generates the first part a QSM model for simulation ."
::=
match modelInfo
case MODELINFO(varInfo=varInfo as  VARINFO(__)) then
  <<
  model <% getName(modelInfo) %> 
    constant Integer N = <%varInfo.numStateVars%>;
    Real x[N](start=xinit());
    discrete Real d[<% listLength(disc) %>](start=dinit());
    Real a[<% listLength(algs) %>]; 

    /* Parameters */ 
    <% generateParameters(modelInfo,parameterEquations) %>

    /* Init functions */
    <% generateInitFunction(modelInfo,states,disc,algs,sampleConditions) %>
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
  a[<% intAdd(List.position(name,vars),1)%>] is <% crefStr(name) %>
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

template generateInitFunction(ModelInfo modelInfo, list<DAE.ComponentRef> states, list<DAE.ComponentRef> disc,
                              list<DAE.ComponentRef> algs,list<SampleCondition> sampleConditions)
 "Generates the initial functions(s)"
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<

  function boolToReal
    input Boolean b;
    output Real r;
  algorithm
    r:=if b then 1.0 else 0.0;
  end boolToReal;

  function pow
    input Real base;
    input Real exp;
    output Real o;
  algorithm
    o:=base^exp;
  end pow;


  function xinit
    output Real x[N];
  algorithm
    <% vars.stateVars |> var hasindex i0 => InitStateVariable(var,states);separator="\n"%>
  end xinit;

  function dinit
    output Real d[<% listLength(disc) %>];
  algorithm
    <% BackendQSS.generateDInit(disc,sampleConditions,vars,0,listLength(disc),1) %>
  end dinit;

  /* Algebraic vars 
    <% vars.algVars |> var hasindex i0 => InitAlgVariable(var,algs);separator="\n"%>
  */

  >>
end generateInitFunction;

template generateAnnotation(Option<SimCode.SimulationSettings> simulationSettingsOpt)
 "Generates the simulation annotation for simulation ."
::=
match simulationSettingsOpt
case SOME(s as SIMULATION_SETTINGS(__)) then
  <<
    annotation(experiment(StartTime = <%s.startTime%>, StopTime = <%s.stopTime%>, Tolerance = 1e-3, AbsTolerance = <%s.tolerance %>, Solver = LIQSS2, Output = {x[1]}, StepSize = <%s.stopTime%>/500));
  >>
end generateAnnotation;

template generateOdeEqs(list<SimEqSystem> odeEquations,list<list<Integer>> indexs, list<DAE.ComponentRef> states,list<DAE.ComponentRef> disc,list<DAE.ComponentRef> algs,Text &funDecls, Text &externalFuncs)
 "Generates the ODE equations of the model"
::=
<<
<% (odeEquations |> eq hasindex i0 => generateOdeEq(eq,listNth(indexs,0),states,disc,algs,&funDecls,&externalFuncs); separator="\n")  %>
>>
end generateOdeEqs;

template generateOdeEq(SimEqSystem odeEquation,list<Integer> indexEq, list<DAE.ComponentRef> states, list<DAE.ComponentRef> disc, list<DAE.ComponentRef> algs, Text &funDecls, Text &externalFuncs)
 "Generates one  ODE equation of the model"
::=
match odeEquation
case SES_SIMPLE_ASSIGN(__) then 
<<
  <% BackendQSS.replaceCref(cref,states,disc,algs) %> = <% ExpressionDump.printExpStr(BackendQSS.replaceVars(exp,states,disc,algs)) %>;
>>
case e as SES_LINEAR(vars=vars,index=index) then 
  let out_vars = (vars |> v => match v case SIMVAR(name=name) then BackendQSS.replaceCref(name,states,disc,algs);separator=",")
  let in_vars =  (BackendQSS.getRHSVars(beqs,vars,simJac,states,disc,algs) |> cref =>
       BackendQSS.replaceCref(cref,states,disc,algs);separator="," ) 
  let &externalFuncs += generateLinear(e,states,disc,algs)
  let &funDecls += 
<<
  
  function fsolve<%index%>
    <% BackendQSS.getRHSVars(beqs,vars,simJac,states,disc,algs) |> v hasindex i0 => 'input Real i<%i0%>;' ;separator="\n" %>
    <% vars |> v hasindex i0 => 'output Real o<%i0%>;' ;separator="\n" %>
  external "C" ;
  end fsolve<%index%>;

>>
<<
  (<% out_vars %>)=fsolve<%index%>(<% in_vars %>);
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
                    BackendDAE.EquationArray eqs)
 "Generates one zc equation of the model"
::=
  <<
  <% (zcs |> zc => generateOneZC(zc,states,disc,algs,eqs);separator="\n") %>
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
                    list<DAE.ComponentRef> disc, list<DAE.ComponentRef> algs, BackendDAE.EquationArray eqs)
"generates one "
::=
  match zc
  case BackendDAE.ZERO_CROSSING(__) then
<<
  when <% ExpressionDump.printExpStr(BackendQSS.replaceVars(relation_,states,disc,algs)) %> then
    <% BackendQSS.generateHandler(eqs,occurEquLst,states,disc,algs,relation_,true) %>
  elsewhen <% ExpressionDump.printExpStr(BackendQSS.replaceVars(BackendQSS.negate(relation_),states,disc,algs)) %> then
    <% BackendQSS.generateHandler(eqs,occurEquLst,states,disc,algs,relation_,false) %>
  end when;
>>
end generateOneZC;

template generateWhen(SimCode.SimWhenClause when, list<DAE.ComponentRef> states, list<DAE.ComponentRef> disc, list<DAE.ComponentRef> algs, Integer index)
::=
match when
case SIM_WHEN_CLAUSE(conditions=conditions,whenEq= SOME(WHEN_EQ(left=left,right=right,elsewhenPart=NONE()))) then
let &extraCode = buffer "" /*BUFD*/
<<
  when <% generateCond(conditions,states,disc,algs,extraCode,intAdd(index,listLength(disc))) %> then 
   <% BackendQSS.replaceCref(left,states,disc,algs) %> := <% ExpressionDump.printExpStr(BackendQSS.replaceVars(right,states,disc,algs)) %>;
   <% extraCode %>
  end when;
>>
case SIM_WHEN_CLAUSE(conditions=conditions,whenEq= SOME(WHEN_EQ(left=left,right=right,elsewhenPart=SOME(__)))) then
let &extraCode = buffer "" /*BUFD*/
<<
  when <% generateCond(conditions,states,disc,algs,extraCode,intAdd(index,listLength(disc))) %> then 
    <% BackendQSS.replaceCref(left,states,disc,algs) %> := <% ExpressionDump.printExpStr(BackendQSS.replaceVars(right,states,disc,algs)) %>;
    <% extraCode %>
  end when;
>>
else
  <<
  /*  NOT MATCHED WHEN */
  >>
end generateWhen;

template generateCond(list<tuple<DAE.Exp, Integer>> conds, list<DAE.ComponentRef> states, 
                      list<DAE.ComponentRef> disc,list<DAE.ComponentRef> algs,Text &extraCode, Integer index)
::=
  match conds
  case ({(DAE.CALL(path=IDENT(name="sample"),expLst={start,interval,_}),_)}) then
  let &extraCode += 
  << 
  d[<% intAdd(index,1) %>] := pre(d[<% intAdd(index,1) %>]) + <%ExpressionDump.printExpStr(BackendQSS.replaceVars(interval,states,disc,algs)) %>;
  >>
  <<
  time > <% ExpressionDump.printExpStr(BackendQSS.replaceVars(start,states,disc,algs)) %> + d[<% intAdd(index,1) %>]
  >>
  case ({(e as DAE.CREF(__),_)}) then
  <<
  <% ExpressionDump.printExpStr(BackendQSS.replaceVars(e,states,disc,algs)) %> > 0.5
  >>
  case ({(DAE.LUNARY(exp=e),_)}) then
  <<
  1 - <% ExpressionDump.printExpStr(BackendQSS.replaceVars(e,states,disc,algs)) %> > 0.5
  >>
  case ({(e,_)}) then
  <<
  <% ExpressionDump.printExpStr(BackendQSS.replaceVars(e,states,disc,algs)) %>
  >>
  else 'initial()'
end generateCond;

template generateDiscont(list<BackendDAE.ZeroCrossing> zcs, list<DAE.ComponentRef> states,
list<DAE.ComponentRef> disc, list<DAE.ComponentRef> algs, list<SimCode.SimWhenClause> whens,BackendDAE.EquationArray eqs)
::=
  <<
  <% generateZC(zcs,states,disc,algs,eqs) %>
  <% whens |> w hasindex i0 => generateWhen(w,states,disc,algs,intSub(i0,listLength(whens)));separator="\n" %>
  >>
end generateDiscont;

template generateLinear(SimEqSystem eq,list<DAE.ComponentRef> states, list<DAE.ComponentRef> disc, list<DAE.ComponentRef> algs)
::=
match eq
case SES_LINEAR(__) then
let &preExp = buffer "" /*BUFD*/
let &varDecls = buffer "" /*BUFD*/
<<

gsl_matrix *A<%index%>,*invA<%index%>;
gsl_vector *b<%index%>,*x<%index%>;
gsl_permutation *p<%index%>;
int init<%index%> = 0;
<% (BackendQSS.getDiscRHSVars(beqs,vars,simJac,states,disc,algs) |> v hasindex i0 => 
  let i=List.position(v,BackendQSS.getRHSVars(beqs,vars,simJac,states,disc,algs))
  'double old_i<%i%>_<%index%>=-1;';separator="\n") %>

void fsolve<%index%>(<%
(BackendQSS.getRHSVars(beqs,vars,simJac,states,disc,algs) |> v hasindex i0 => 'double i<%i0%>';separator=",") 
%>,<%vars |> SIMVAR(__) hasindex i0 => 'double *o<%i0%>' ;separator=","%>)
{
  const int DIM = <% listLength(beqs) %>;
  int invert_matrix = 0;
  int signum;

  invert_matrix = 0;
  
  <% 
  (BackendQSS.getDiscRHSVars(beqs,vars,simJac,states,disc,algs) |> v hasindex i0 =>
  let i=List.position(v,BackendQSS.getRHSVars(beqs,vars,simJac,states,disc,algs))
  'if (old_i<%i%>_<%index%>!=i<%i%>) {
    invert_matrix=1;
    old_i<%i%>_<%index%>=i<%i%>;
}';separator="\n") %>

  if (!init<%index%>) {
    /* Alloc space */
    A<%index%> = gsl_matrix_alloc(DIM, DIM);
    invA<%index%> = gsl_matrix_alloc(DIM, DIM);
    b<%index%> = gsl_vector_alloc(DIM);
    x<%index%> = gsl_vector_alloc(DIM);
    p<%index%> = gsl_permutation_alloc(DIM);
    init<%index%>=1;
    invert_matrix=1;
  }
  
  /* Fill B */
  <%beqs |> exp hasindex i0 => 
    'gsl_vector_set(b<%index%>,<%i0%>,<% 
      System.stringReplace(CodegenC.daeExp(
        BackendQSS.replaceVarsInputs(exp,BackendQSS.getRHSVars(beqs,vars,simJac,states,disc,algs)),
        contextOther,&preExp,&varDecls),"$P","") %>);';separator=\n%>

  /* Invert matrix if necesary */
  if (invert_matrix) 
  {
    /* Fill A */
    gsl_matrix_set_zero(A<%index%>);
    <%simJac |> (row, col, eq as SES_RESIDUAL(__)) =>
     'gsl_matrix_set(A<%index%>, <%row%>, <%col%>,<%  System.stringReplace(CodegenC.daeExp(
        BackendQSS.replaceVarsInputs(eq.exp,BackendQSS.getRHSVars(beqs,vars,simJac,states,disc,algs)),
        contextOther,&preExp,&varDecls),"$P","") %>);'
    ;separator="\n"%>
    gsl_linalg_LU_decomp(A<%index%>, p<%index%>, &signum);
    gsl_linalg_LU_invert(A<%index%>, p<%index%> ,invA<%index%>);
  }
  
  /* Copmute x=inv(A)*b */ 
  gsl_blas_dgemv(CblasNoTrans,1.0,invA<%index%>,b<%index%>,0.0,x<%index%>);
  /* Get x values out */
  <%vars |> v hasindex i0 => '*o<%i0%> = gsl_vector_get(x<%index%>, <%i0%>);' ;separator="\n"%>
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
end CodegenQSS;
