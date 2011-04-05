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
import SimCodeDump;

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
  let()= textFile(structureFile(simCode), 'modelica_struct.pds')
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
case SIMCODE(modelInfo=modelInfo as MODELINFO(varInfo=varInfo as  VARINFO(__))) then
  <<

  <%SimCodeC.simulationFileHeader(simCode)%>

  <%SimCodeC.externalFunctionIncludes(externalFunctionIncludes)%>

  #ifdef _OMC_MEASURE_TIME
  int measure_time_flag = 1;
  #else
  int measure_time_flag = 0;
  #endif

  <%SimCodeC.globalData(modelInfo,fileNamePrefix)%>

  // fbergero, xfloros: Code for QSS methods
  #ifdef _OMC_QSS

  bool cond[<%modelInfo.varInfo.numZeroCrossings%>];

  void set_condition_to(unsigned int c, bool b) { cond[c]=b; }
  bool condition(unsigned int c) { return cond[c]; }

  //for QSS solver 
  double rel_accuracy = 1e-5;
  double abs_accuracy = 1e-5;
  char* method = "QSS3";

  double state_values(int state) 
  {
    return 0.0;
  }
	
  double quantum_values(int state)
  {
    return 0.0;
  }

  // integration method 
  char* int_method() {
    return method;
  }

  // settings 
  double function_rel_acc() {
    return rel_accuracy;
  }

  double function_abs_acc() {
    return abs_accuracy;
  }

  <%functionQssStaticBlocks(odeEquations,zeroCrossings)%>

  <%functionQssWhen(BackendQSS.replaceCondWhens(whenClauses,helpVarInfo,zeroCrossings),helpVarInfo,zeroCrossings)%>

  <%functionQssSample(zeroCrossings)%>

  <%functionQssUpdateDiscrete(allEquations,zeroCrossings)%>

  #endif
  
  <%SimCodeC.equationInfo(appendLists(appendAllequation(JacobianMatrixes),allEquations))%>
  
  <%SimCodeC.functionGetName(modelInfo)%>
  
  <%SimCodeC.functionSetLocalData()%>
  
  <%SimCodeC.functionInitializeDataStruc()%>

  <%SimCodeC.functionCallExternalObjectConstructors(extObjInfo)%>
  
  <%SimCodeC.functionDeInitializeDataStruc(extObjInfo)%>
  
  <%SimCodeC.functionExtraResiduals(allEquations)%>

  <%SimCodeC.functionInput(modelInfo)%>
  
  <%SimCodeC.functionOutput(modelInfo)%>

  <%SimCodeC.functionInitSample(sampleConditions)%>
  
  <%SimCodeC.functionSampleEquations(sampleEquations)%>

  <%SimCodeC.functionStoreDelayed(delayedExps)%>

  <%SimCodeC.functionInitial(initialEquations)%>
  
  <%SimCodeC.functionInitialResidual(residualEquations)%>
  
  <%SimCodeC.functionBoundParameters(parameterEquations)%>
  
  <%SimCodeC.functionODE(odeEquations)%>
  
  <%SimCodeC.functionODE_residual()%>
  
  <%SimCodeC.functionAlgebraic(algebraicEquations)%>
    
  <%SimCodeC.functionAliasEquation(removedEquations)%>
                       
  <%SimCodeC.functionDAE(allEquations, whenClauses, helpVarInfo)%>
    
  <%SimCodeC.functionOnlyZeroCrossing(zeroCrossings)%>
  
  <%SimCodeC.functionCheckForDiscreteChanges(discreteModelVars)%>
  
  <%SimCodeC.functionAssertsforCheck(algorithmAndEquationAsserts)%>
  
  <%SimCodeC.generateLinearMatrixes(JacobianMatrixes)%>
  
  <%SimCodeC.functionlinearmodel(modelInfo)%>
  
  <%\n%> 
  >>
  /* adrpo: leave a newline at the end of file to get rid of the warning */
end simulationFile;

template structureFile(SimCode simCode)
 "Generates structure for main C file for simulation target."
::=
  let &models = buffer "" /*BUFD*/
  let connections = generateConnections()
match simCode
case SIMCODE(modelInfo=modelInfo as MODELINFO(varInfo=varInfo as  VARINFO(__))) then
  <<
  Root-Coordinator
  {
    <%generateIntegrators()%>
    <%generateStaticBlocks()%>
    <%generateZeroCrossingFunctions(zeroCrossings)%>
    <%generateCrossingDetectors(zeroCrossings)%>
    <%generateWhenBlocks(whenClauses,helpVarInfo)%>
    <%generateSampleBlocks(zeroCrossings)%>
    Simulator
      {
        Path = modelica/outvars.h
        Parameters = 1.0
      }
    EIC
      {
      }
    EIC
      {
      }
    IC
      {
        <%connections%>
      }
  }
  
  >>
end structureFile;

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

template functionQssWhen(list<SimWhenClause> whenClauses, list<HelpVarInfo> helpVars,list<ZeroCrossing> zeroCrossings)
  "Generates function for when in simulation file."
::=
  let &varDecls = buffer "" /*BUFD*/
	let whenCases = functionQssWhen2(whenClauses,helpVars,varDecls,zeroCrossings)
  <<
  bool functionQssWhen(unsigned int whenIndex, double *out, double *in)
  {
    state mem_state;
    <%varDecls%>
    mem_state = get_memory_state();
    switch (whenIndex)
    {
 	  <% whenCases %>
    }
    restore_memory_state(mem_state);
  }
  >>
end functionQssWhen;


template functionQssWhen2(list<SimWhenClause> whenClauses, list<HelpVarInfo> helpVars, Text &varDecls,list<ZeroCrossing> zeroCrossings)
  "Generates function for when in simulation file."
::= 
	(whenClauses |> SIM_WHEN_CLAUSE (__) hasindex i0 =>
  	let &preExp = buffer "" /*BUFD*/
		let cond = functionPreWhenCondition(conditions,varDecls,preExp, zeroCrossings) 
		let equations = generateWhenEquations(reinits,whenEq,varDecls)
  <<
  case <% i0 %>:
    #ifdef _OMC_OMPD
    #endif
    <% preExp %>
    if (<% cond %>) {
      <% equations %>
    } else {
    }
    #ifdef _OMC_OMPD
    #endif
    break;
  >>
 	;separator="\n")
end functionQssWhen2;

template generateWhenEquations(list<BackendDAE.WhenOperator> reinits,Option<BackendDAE.WhenEquation> whenEq, Text &varDecls)
  "Generate the when equtions"
::=
  match whenEq
	case SOME(BackendDAE.WHEN_EQ(right=right,left=left)) then
	let &preExp = buffer ""
  let exp = SimCodeC.daeExp(right, contextSimulationDiscrete, &preExp /*BUFC*/, &varDecls /*BUFD*/)
	<<
	<% SimCodeC.cref(left) %>  = <% exp %>;
	<% generateReinits(reinits,varDecls) %>
	>>
	case NONE() then
	generateReinits(reinits,varDecls)
end generateWhenEquations;

template generateReinits(list<BackendDAE.WhenOperator> reinits, Text &varDecls)
  "Generate the reinit when equtions"
::=
  (reinits |> BackendDAE.REINIT(stateVar=stateVar, value=value) =>
	let &preExp = buffer ""
	let val = SimCodeC.daeExp(value, contextSimulationDiscrete, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  <<
  <% SimCodeC.cref(stateVar) %> = <% val %>; // Reinit of var <% SimCodeC.cref(stateVar) %> 
	>>;separator="\n")
end generateReinits;



template functionPreWhenCondition (list<tuple<DAE.Exp, Integer>> conditions, Text &varDecls /* BUFD */, Text &preExp, list<ZeroCrossing> zeroCrossings)
  "Generate conditions for when eq"
::=
  (conditions |> (e,hvar) => 
	match e
	case CALL(path=IDENT(name="samplecondition"),expLst={DAE.ICONST(integer=i)}) then
	'condition(<% i %>)'
	case _ then
  let helpInit = SimCodeC.daeExp(e, contextSimulationDiscrete, &preExp /*BUFC*/, &varDecls /*BUFD*/)
	let &preExp += <<localData->helpVars[<%hvar%>] = <% helpInit %>;

	>>
	'edge(localData->helpVars[<%hvar%>])'
	;separator=" || ")
end functionPreWhenCondition;

template functionQssStaticBlocks(list<SimEqSystem> derivativEquations,list<ZeroCrossing> zeroCrossings)
  "Generates function in simulation file."
::=
  let &varDecls = buffer "" /*BUFD*/
	let zeroCross = generateZeroCrossingsEq(listLength(derivativEquations),zeroCrossings,varDecls)
	let staticFun = generateStaticFunc(derivativEquations,zeroCrossings,varDecls)
  <<
  void functionQssStaticBlocks(int staticFunctionIndex, double t, double *in, double *out)
  {
    state mem_state;
    <%varDecls%>
    mem_state = get_memory_state();
    switch (staticFunctionIndex)
    {
      <% staticFun %>
      <% zeroCross %>
    }
    restore_memory_state(mem_state);
  }
  >>
end functionQssStaticBlocks;

template generateStaticFunc(list<SimEqSystem> odeEq,list<ZeroCrossing> zeroCrossings, Text &varDecls /*BUFP*/)
"Generate the cases for the static function "
::= 
  (odeEq |> eq hasindex i0 =>
		match eq
		case SES_SIMPLE_ASSIGN(__) then
    <<

    case <% i0 %>:
      // Read inputs from in[]
      #ifdef _OMC_OMPD
      #endif

      // Evalute the static function
      <% SimCodeC.equation_(BackendQSS.replaceZC(eq,zeroCrossings), contextSimulationNonDiscrete, &varDecls /*BUFC*/) %>

      // Write outputs to out[]
      #ifdef _OMC_OMPD
      #endif
      break;
    >>
		case _ then 
		<<
		>>
  ;separator="\n")
end generateStaticFunc;


template generateZeroCrossingsEq(Integer offset,list<ZeroCrossing> zeroCrossings,Text &varDecls /*BUFP*/)
"Generate the cases for the zero crossings"
::= 
  (zeroCrossings |> ZERO_CROSSING(__) hasindex i0 =>
   let &preExp = buffer "" /*BUFD*/
   let zcExp = SimCodeC.daeExp(relation_, contextSimulationDiscrete, &preExp /*BUFC*/, &varDecls /*BUFD*/)
	 match relation_
	 case CALL(path=IDENT(name="sample")) then
  <<

  case <%intAdd(i0,offset)%>:
    // This zero crossing is a sample. This case should not be called
    break;
  >>
	case _ then
  <<

  case <%intAdd(i0,offset)%>:
    #ifdef _OMC_OMPD
    // Read inputs from in[]
    #endif
    // Evalute the ZeroCrossing function
    <%preExp%>
    // Write outputs to out[]
    out[0] = <% zcExp %>;
    break;
  >>
  ;separator="\n")
end generateZeroCrossingsEq;

template functionQssUpdateDiscrete(list<SimEqSystem> allEquationsPlusWhen,list<ZeroCrossing> zeroCrossings)
  "Generates function in simulation file."
::=
  let &varDecls = buffer "" /*BUFD*/
  let eqs = (allEquationsPlusWhen |> eq => generateDiscUpdate(BackendQSS.replaceZC(eq,zeroCrossings), zeroCrossings, &varDecls); separator="\n")
  <<
  void functionQssUpdateDiscrete(double time)
  {
    state mem_state;
    <%varDecls%>
    mem_state = get_memory_state();
    <%eqs%>
    restore_memory_state(mem_state);
  }
  >>
end functionQssUpdateDiscrete;

template generateDiscUpdate(SimEqSystem eq, list<ZeroCrossing> zeroCrossings, Text &varDecls)
	"Generate the updates of the disc variavbles
	author: fbergero"
::=
	match eq 
	case SES_MIXED(__) then
	let disc = (discEqs |> SES_SIMPLE_ASSIGN(__) =>
  	let &preDisc = buffer "" /*BUFD*/
		let expPart = SimCodeC.daeExp(exp, contextSimulationDiscrete, &preDisc /* BUFC */, &varDecls /* BUFD */)
	<<
    <%preDisc%>
    <%SimCodeC.cref(cref)%> = <%expPart%>;
	>>
    ;separator="\n")
	<<
    <%disc%>
	>>

  /*
	case SES_SIMPLE_ASSIGN(__) then
  	let &preDisc = buffer "" /*BUFD*/
		let expPart = SimCodeC.daeExp(exp, contextSimulationDiscrete, &preDisc /* BUFC */, &varDecls /* BUFD */)
	<<
    <%preDisc%>
    <%SimCodeC.cref(cref)%> = <%expPart%>;
	>>
	*/
	case _ then ''
end generateDiscUpdate;


template generateIntegrators()
"Function to generate the integrator atomics for the DEVS structure"
::= 
  <<Simulator
    {
      Path = modelica/modelica_integrator.h
      Parameters = 1.0
    }
  >>
end generateIntegrators;

template generateStaticBlocks()
"Function to generate the static functions atomics for the DEVS structure"
::= 
  <<Simulator
    {
      Path = modelica/modelica_qss_static.h
      Parameters = 1.0,2.0,3.0
    }
  >>
end generateStaticBlocks;

template generateZeroCrossingFunctions(list<ZeroCrossing> zeroCrossings)
"Function to generate the crossing functions atomics for the DEVS structure"
::= 
  let &varDecls = buffer "" /*BUFD*/
  let &preExp = buffer "" /*BUFD*/
  (zeroCrossings |> ZERO_CROSSING(relation_ = DAE.RELATION()) hasindex i0 =>
  <<Simulator
    {
      Path = modelica/modelica_qss_static.h // Crossing function <%i0%> for <% SimCodeC.daeExp(relation_, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/) %>
      Parameters = (double)(<% i0 %>),2.0,1.0
    }
  >>
  ;separator="\n")
end generateZeroCrossingFunctions;

template generateCrossingDetectors(list<ZeroCrossing> zeroCrossings)
"Function to generate the crossing detector atomics for the DEVS structure"
::= 
  let &varDecls = buffer "" /*BUFD*/
  let &preExp = buffer "" /*BUFD*/
  (zeroCrossings |> ZERO_CROSSING(relation_ = DAE.RELATION()) hasindex i0 =>
  <<Simulator
    {
      Path = modelica/modelica_qss_crossdetect.h // Crossing detector <%i0%> for <% SimCodeC.daeExp(relation_, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/) %>
      Parameters = (double)(<% i0 %>),2.0,3.0
    }
  >>
  ;separator="\n")
end generateCrossingDetectors;

template generateWhenBlocks(list<SimWhenClause> whenClauses, list<HelpVarInfo> helpVars)
"Function to generate the when blocks atomics for the DEVS structure"
::= 
  (whenClauses |> _ hasindex i0 =>
  <<Simulator
    {
      Path = modelica/modelica_when_discrete.h // When clause <% i0 %>
      Parameters = (double)(<% i0 %>),2.0,3.0
    }
  >>
  ;separator="\n")
end generateWhenBlocks;

template generateSampleBlocks(list<ZeroCrossing> zeroCrossings)
"Function to generate the when blocks atomics for the DEVS structure"
::= 
  let &varDecls = buffer "" /*BUFD*/
  let &preExp = buffer "" /*BUFD*/
  (zeroCrossings |> ZERO_CROSSING(relation_ = CALL(path=IDENT(name="sample"), expLst={start, interval})) hasindex i0 =>
    let e1 = SimCodeC.daeExp(start, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let e2 = SimCodeC.daeExp(interval, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  <<Simulator
    {
      Path = modelica/modelica_sample.h // Sample block <% i0 %> for sample(<% e1 %>, <% e2 %>)
      Parameters = (double)(<% i0 %>)
    }
  >>
  ;separator="\n")
end generateSampleBlocks;

template generateConnections()
"Function to generate the connections between atomics for the DEVS structure"
::= 
  <<(0,0) ; (12,45) // Connection between 
  (0,0) ; (12,45) // Connection between 
  (0,0) ; (12,45) // Connection between 
  (0,0) ; (12,45) // Connection between 
  (0,0) ; (12,45) // Connection between 
  >>
end generateConnections;

end SimCodeQSS;

// vim: filetype=susan sw=2 sts=2
