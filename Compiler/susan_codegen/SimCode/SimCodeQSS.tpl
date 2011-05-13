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

template translateModel(SimCode simCode,QSSinfo qssInfo) 
 "Generates C code and Makefile for compiling and running a simulation of a
  Modelica model."
::=
match simCode
case SIMCODE(modelInfo=modelInfo as MODELINFO(__)) then
  let()= textFile(simulationFile(simCode,qssInfo), 'modelica_funcs.cpp')
  let()= textFile(SimCodeC.simulationFunctionsHeaderFile(fileNamePrefix, modelInfo.functions, recordDecls), 'model_functions.h')
  let()= textFile(simulationFunctionsFile(fileNamePrefix, modelInfo.functions, literals), 'model_functions.cpp')
  let()= textFile(SimCodeC.recordsFile(fileNamePrefix, recordDecls), 'model_records.c')
  let()= textFile(simulationMakefile(simCode), '<%fileNamePrefix%>.makefile')
  let()= textFile(structureFile(simCode,qssInfo), 'modelica_structure.pds')
  if simulationSettingsOpt then //tests the Option<> for SOME()
     let()= textFile(SimCodeC.simulationInitFile(simCode), 'model_init.txt')
     "" //empty result for true case 
  //else "" //the else is automatically empty, too
  //this top-level template always returns an empty result 
  //since generated texts are written to files directly
end translateModel;

template simulationFile(SimCode simCode, QSSinfo qssInfo)
 "Generates code for main C file for simulation target."
::=
match simCode
case SIMCODE(modelInfo=modelInfo as MODELINFO(varInfo=varInfo as  VARINFO(__))) then
  <<

  <%simulationFileHeader(simCode)%>

  #ifdef _OMC_QSS
  extern "C" { // adrpo: this is needed for Visual C++ compilation to work!
    const char *model_name="<%SimCodeC.dotPath(modelInfo.name)%>";
    const char *model_fileprefix="model";
    const char *model_dir="<%modelInfo.directory%>";
  }
  #endif
 

  <%SimCodeC.globalData(modelInfo,fileNamePrefix)%>

  <%SimCodeC.equationInfo(appendLists(appendAllequation(JacobianMatrixes),allEquations))%>

  <%SimCodeC.functionInitialResidual(residualEquations)%>

  <%SimCodeC.functionExtraResiduals(allEquations)%>

  <%SimCodeC.externalFunctionIncludes(externalFunctionIncludes)%>

  <%SimCodeC.functionODE_residual()%>

  #ifdef _OMC_MEASURE_TIME
  int measure_time_flag = 1;
  #else
  int measure_time_flag = 0;
  #endif

  // fbergero, xfloros: Code for QSS methods
  #ifdef _OMC_QSS
  
  bool isState(int i)
  {
    switch (i)
    {
      <% match qssInfo 
         case QSSINFO(__) then
         <<
         <% outVarLst |> i hasindex i0 =>
         <<
         case <% i0 %>:
            return <% BackendVariable.isStateVar(i) %>;
            break;
         >>; separator="\n" %>
         >>
      %>
    }
  }

  int algNumber(int i)
  {
    switch (i)
    {
      <% match qssInfo 
         case QSSINFO(__) then
         <<
         <% outVarLst |> i hasindex i0 =>
         <<
         case <% i0 %>:
            return <% BackendVariable.varIndex(i) %>;
            break;
         >>; separator="\n" %>
         >>
      %>
    }
  }

  int stateNumber(int i)
  {
    switch (i)
    {
      <% match qssInfo 
         case QSSINFO(__) then
         <<
         <% outVarLst |> i hasindex i0 =>
         <<
         case <% i0 %>:
            return <% BackendVariable.varIndex(i) %>;
            break;
         >>; separator="\n" %>
         >>
      %>
 
    }
  }

  int
  startInteractiveSimulation(int, char**);
  int
  startNonInteractiveSimulation(int, char**);
  int
  initRuntimeAndSimulation(int, char**);
  <%generateIncidenceMatrix(BackendQSS.generateConnections(qssInfo))%>
  extern int interactiveSimulation;
  <%generateInputVars(BackendQSS.getAllInputs(qssInfo))%>
  <%generateOutputVars(BackendQSS.getAllOutputs(qssInfo))%>

  #ifdef _OMC_OMPD_MAIN
  int
  main(int argc, char**argv)
  {
    int retVal = -1;
  
    if (initRuntimeAndSimulation(argc, argv)) //initRuntimeAndSimulation returns 1 if an error occurs
      return 1;

    if (interactiveSimulation) {
      //cout << "startInteractiveSimulation: " << version << endl;
      retVal = startInteractiveSimulation(argc, argv);
    } else {
      //cout << "startNonInteractiveSimulation: " << version << endl;
      retVal = startNonInteractiveSimulation(argc, argv);
    }

    deInitializeDataStruc(globalData);
    free(globalData);
    fflush(NULL);
    EXIT(retVal);
  }
  #endif

  #define condition_rettype bool
  void init_ompd();
  void clean_ompd();

  bool cond[<%modelInfo.varInfo.numZeroCrossings%>];

  void set_condition_to(unsigned int c, bool b) { cond[c]=b; }
  bool condition(unsigned int c) { return cond[c]; }

  //for QSS solver 
  double rel_accuracy = 1e-5;
  double abs_accuracy = 1e-5;
  char* method = (char*)"QSS3";

  double state_values(int state) 
  {
    switch (state)
    {
      <% generateStateValues(qssInfo) %>
    }
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

  int init_runtime()
  {
    static bool init=false;
    if (!init)
    {
      init=true;
      init_ompd();
    }
    return 0;
  }

  void clean_runtime()
  {
    static bool clean=false;
    if (!clean)
    {
      clean=true;
      clean_ompd();
    }
  }
  <%functionQssStaticBlocks(odeEquations,zeroCrossings,qssInfo,modelInfo.varInfo.numStateVars)%>

  <%functionQssWhen(BackendQSS.replaceCondWhens(whenClauses,helpVarInfo,zeroCrossings),helpVarInfo,zeroCrossings)%>

  <%functionQssSample(zeroCrossings)%>

  <%functionQssUpdateDiscrete(allEquations,zeroCrossings)%>

  #endif
  
  <%SimCodeC.functionGetName(modelInfo)%>
  
  <%SimCodeC.functionSetLocalData()%>
  
  <%SimCodeC.functionInitializeDataStruc()%>

  <%SimCodeC.functionCallExternalObjectConstructors(extObjInfo)%>
  
  <%SimCodeC.functionDeInitializeDataStruc(extObjInfo)%>
  
  <%SimCodeC.functionInput(modelInfo)%>
  
  <%SimCodeC.functionOutput(modelInfo)%>

  <%SimCodeC.functionInitSample(sampleConditions)%>
  
  <%SimCodeC.functionSampleEquations(sampleEquations)%>

  <%SimCodeC.functionStoreDelayed(delayedExps)%>

  <%SimCodeC.functionInitial(initialEquations)%>
  
  <%SimCodeC.functionBoundParameters(parameterEquations)%>
  
  <%SimCodeC.functionODE(odeEquations,"")%>
  
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

template structureFile(SimCode simCode, QSSinfo qssInfo)
 "Generates structure for main C file for simulation target."
::=
  let &models = buffer "" /*BUFD*/
  let connections = generateConnections(BackendQSS.generateConnections(qssInfo))
match simCode
case SIMCODE(modelInfo=modelInfo as MODELINFO(varInfo=varInfo as  VARINFO(__))) then
  <<
  Root-Coordinator
  {
    <%generateIntegrators(varInfo.numStateVars)%>
    <%generateStaticBlocks(qssInfo,varInfo.numStateVars)%>
    <%generateZeroCrossingFunctions(zeroCrossings,qssInfo,varInfo.numStateVars)%>
    <%generateCrossingDetector(zeroCrossings,qssInfo)%>
    <%generateWhenBlocks(whenClauses,helpVarInfo)%>
    Simulator
      {
        Path = modelica/outvars.h
        Parameters = 0.0
      }
    EIC
      {
      }
    EIC
      {
      }
    IC
      {
        <% connections %>
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
  bool functionQssWhen(unsigned int whenIndex, double t,double *out, double *in)
  {
    state mem_state;
    time = t;
    <%varDecls%>
    mem_state = get_memory_state();
    switch (whenIndex)
    {
 	  <% whenCases %>
    }
    return false;
  }
  >>
end functionQssWhen;


template functionQssWhen2(list<SimWhenClause> whenClauses, list<HelpVarInfo> helpVars, Text &varDecls,list<ZeroCrossing> zeroCrossings)
  "Generates function for when in simulation file."
::= 
	(whenClauses |> SIM_WHEN_CLAUSE (__) hasindex i0 =>
  	let &preExp = buffer "" /*BUFD*/
  	let &saves = buffer "" /*BUFD*/
		let cond = functionPreWhenCondition(conditions,varDecls,preExp, zeroCrossings) 
		let equations = generateWhenEquations(reinits,whenEq,varDecls)
  <<
  case <% i0 %>:
    #ifdef _OMC_OMPD
    // Read inputs from in[]
    #endif
    <% preExp %>
    if (<% cond %>) {
      <% equations %>
			<%saves%>
      restore_memory_state(mem_state);
      return true;
    } else {
			<%saves%>
      restore_memory_state(mem_state);
      return false;
    }
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

template functionQssStaticBlocks(list<SimEqSystem> derivativEquations,list<ZeroCrossing> zeroCrossings, QSSinfo qssInfo, Integer nStates)
  "Generates function in simulation file."
::=
	match qssInfo
	case BackendQSS.QSSINFO(__) then
  	let &varDecls = buffer "" /*BUFD*/
		let numStatic = intAdd(listLength(eqs),listLength(zeroCrossings))
		let numPureStatic = listLength(eqs)
		let numZeroCross = listLength(zeroCrossings)
		let staticFun = generateStaticFunc(derivativEquations,zeroCrossings,varDecls,DEVSstructure,eqs,outVarLst,nStates)
		let zeroCross = generateZeroCrossingsEq(listLength(eqs),zeroCrossings,varDecls,DEVSstructure,outVarLst,nStates)

  <<
  int staticBlocks = <% numStatic %>;
  int staticPureBlocks = <% numPureStatic %>;
  int zeroCrossings = <% numZeroCross %>;

  void function_staticBlocks(int staticFunctionIndex, double t, double *in, double *out)
  {
    state mem_state;
    <%varDecls%>
    // Number of Static blocks: <% numStatic %>
    time = t;
    mem_state = get_memory_state();
    switch (staticFunctionIndex)
    {
      <% staticFun %>
      // Start of zero crossings functions
      <% zeroCross %>
    }
    restore_memory_state(mem_state);
  }
  >>
end functionQssStaticBlocks;

template generateOutputs(BackendQSS.DevsStruct devsst, Integer index, list<BackendDAE.Var> varLst, Integer nStates)
"Generate outputs for static blocks"
::= 
	(BackendQSS.getOutputs(devsst,intAdd(index,intAdd(1,nStates))) |> i hasindex i0 =>
	<<
	// Output <% i0 %> is var <% i %>
	out[<% i0 %>] =  <% BackendQSS.derPrefix(listNth(varLst,intAdd(i,-1)))%><% SimCodeC.cref(BackendVariable.varCref(listNth(varLst,intAdd(i,-1)))) %>;
	>>
	; separator="\n")
end generateOutputs;


template generateInputs(BackendQSS.DevsStruct devsst, Integer index, list<BackendDAE.Var> varLst, Integer nStates)
"Generate inputs for static blocks"
::= 
	(BackendQSS.getInputs(devsst,index) |> i hasindex i0 =>
	<<
	// Input <% i0 %> is var <% i %>
	<% SimCodeC.cref(BackendVariable.varCref(listNth(varLst,intAdd(i,-1)))) %> = in[<% i0 %>];
	>>
	; separator="\n")
end generateInputs;

template generateStaticFunc(list<SimEqSystem> odeEq,list<ZeroCrossing> zeroCrossings, 
	Text &varDecls /*BUFP*/, BackendQSS.DevsStruct devsst,list<list<SimCode.SimEqSystem>> BLTblocks, list<BackendDAE.Var> varLst, Integer nStates)
"Generate the cases for the static function "
::= 
  (BLTblocks |> eqs hasindex i0 =>
    <<

    case <% i0 %>:
      {
      // Read inputs from in[]
      #ifdef _OMC_OMPD
      <% generateInputs(devsst,intAdd(intAdd(i0,nStates),1),varLst,nStates) %>
      #endif

      // Evalute the static function
      <% (eqs |> eq => SimCodeC.equation_(BackendQSS.replaceZC(eq,zeroCrossings), contextSimulationNonDiscrete, &varDecls /*BUFC*/); separator="\n") %>

      // Write outputs to out[]
      #ifdef _OMC_OMPD
      <% generateOutputs(devsst,i0,varLst,nStates) %>
      #endif
      break;
      }
    >>
  ;separator="\n")
end generateStaticFunc;

template generateRelation(DAE.Operator op, String e1, String e2)
::=
  match op
  case LESS(__) then '<% e1 %> - <% e2 %>'
  case LESSEQ(__) then '<% e1 %> - <% e2 %>'
  case GREATER(__) then '<% e2 %> - <% e1 %>'
  case GREATEREQ(__) then '<% e2 %> - <% e1 %>'
  case EQUAL(__) then '<% e1 %> - <% e2 %>'
  case NEQUAL(__) then '<% e2 %> - <% e1 %>'
end generateRelation;

template generateZCExp(DAE.Exp exp, Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
"Generate the  ZC exp by substracting both arguments
  author: fbergero"
::=
  match exp
  case e as RELATION(__) then
    let e1 = SimCodeC.daeExp(exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let e2 = SimCodeC.daeExp(exp2, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let sub = generateRelation(operator,e1,e2)
  <<
  <% sub %>
  >>
  case e as CALL(path=IDENT(name="sample")) then
  <<
  >>
  else SimCodeC.error(sourceInfo(), 'Unhandled expression in SimCodeQSS.generateZCExp: <%ExpressionDump.printExpStr(exp)%>')
end generateZCExp;

template generateZeroCrossingsEq(Integer offset,list<ZeroCrossing> zeroCrossings,Text &varDecls /*BUFP*/, 
                                 BackendQSS.DevsStruct devsst,list<BackendDAE.Var> varLst,Integer nStates)
"Generate the cases for the zero crossings"
::= 
  (zeroCrossings |> ZERO_CROSSING(__) hasindex i0 =>
   let &preExp = buffer "" /*BUFD*/
   let zcExp = generateZCExp(relation_, contextSimulationDiscrete, &preExp /*BUFC*/, &varDecls /*BUFD*/)
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
    {
    #ifdef _OMC_OMPD
    // Read inputs from in[]
    <% generateInputs(devsst,intAdd(offset,intAdd(i0,intAdd(1,nStates))),varLst,nStates) %>
    #endif
    // Evalute the ZeroCrossing function
    <%preExp%>
    // Write outputs to out[]
    out[0] = <% zcExp %>;
    break;
    }
  >>
  ;separator="\n")
end generateZeroCrossingsEq;

template functionQssUpdateDiscrete(list<SimEqSystem> allEquationsPlusWhen,list<ZeroCrossing> zeroCrossings)
  "Generates function in simulation file."
::=
  let &varDecls = buffer "" /*BUFD*/
  let eqs = (allEquationsPlusWhen |> eq => generateDiscUpdate(BackendQSS.replaceZC(eq,zeroCrossings), zeroCrossings, &varDecls); separator="\n")
  <<
  void function_updateDepend(double t, int index)
  {
    state mem_state;
    time = t;
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


template generateIntegrators(Integer nStates)
"Function to generate the integrator atomics for the DEVS structure"
::= 
	(Util.listFill(0,nStates) |> i hasindex i0 =>
  <<Simulator
    {
      Path = modelica/modelica_qss_integrator.h
      Parameters = <% i0 %>.0 // Index
    }
  >>
	;separator="\n")
end generateIntegrators;

template generateStaticBlocks(QSSinfo qssInfo, Integer nStates)
"Function to generate the static functions atomics for the DEVS structure"
::= 
	match qssInfo
	case QSSINFO(DEVSstructure = BackendQSS.DEVS_STRUCT(__)) then
	(eqs |> eq hasindex i0 =>
  <<Simulator
    {
      Path = modelica/modelica_qss_static.h
      Parameters = <% BackendQSS.numInputs(qssInfo,intAdd(i0,intAdd(1,nStates)))
				%>.0, <%
				BackendQSS.numOutputs(qssInfo,intAdd(i0,intAdd(1,nStates))) %>.0, <% i0 %>.0 // Inputs, Outputs, Index
    }
  >>
	;separator="\n")
end generateStaticBlocks;

template generateZeroCrossingFunctions(list<ZeroCrossing> zeroCrossings,QSSinfo qssInfo,Integer nStates)
"Function to generate the crossing functions atomics for the DEVS structure"
::= 
  match qssInfo
  case QSSINFO(__) then
  let &varDecls = buffer "" /*BUFD*/
  let numStatic = listLength(eqs)
  let &preExp = buffer "" /*BUFD*/
  (zeroCrossings |> ZERO_CROSSING(relation_ = DAE.RELATION()) hasindex i0 =>
  <<Simulator // Block # <% intAdd(intAdd(listLength(eqs),nStates),i0) %>
    {
      Path = modelica/modelica_qss_static.h // Crossing function <%i0%> for <% SimCodeC.daeExp(relation_, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/) %>
      Parameters = <% BackendQSS.numInputs(qssInfo,intAdd(i0,intAdd(listLength(eqs),intAdd(nStates,1)))) %>.0, 1.0, <% intAdd(i0,listLength(eqs))%>.0 // Inputs, Outputs, Index
    }
  >>
  ;separator="\n")
end generateZeroCrossingFunctions;

template generateCrossingDetector(list<ZeroCrossing> zeroCrossings,QSSinfo qssInfo)
"Function to generate the crossing detectors atomics for the DEVS structure"
::= 
  match qssInfo
  case QSSINFO(__) then
  let &varDecls = buffer "" /*BUFD*/
  let numStatic = listLength(eqs)
  let &preExp = buffer "" /*BUFD*/
  (zeroCrossings |> ZERO_CROSSING(relation_ = DAE.RELATION()) hasindex i0 =>
  <<Simulator
    {
      Path = modelica/modelica_qss_cross_detect.h // Crossing detector <%i0%> for <% SimCodeC.daeExp(relation_, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/) %>
      Parameters = <% i0 %>.0
    }
  >>
  ;separator="\n")
end generateCrossingDetector;

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

template generateConnections(list<list<Integer>> conns)
"Function to generate the connections between atomics for the DEVS structure"
::= 
  ( conns |> c =>
  << (<%listNth(c,0)%>,<%listNth(c,1)%>) ; (<%listNth(c,2)%>,<%listNth(c,3)%>) 
  >>
  ;separator="\n")
end generateConnections;

template generateStateValues(BackendQSS.QSSinfo qssInfo) 
"Generate the intial state values"
::= 
  ( BackendQSS.getStates(qssInfo) |> var hasindex i0 =>
  <<
  case <% i0 %>:
    return  <% SimCodeC.cref(BackendVariable.varCref(var)) %>;
  >>
  ;separator="\n")
end generateStateValues;

template simulationMakefile(SimCode simCode)
 "Generates the contents of the makefile for the simulation case."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__), makefileParams=MAKEFILE_PARAMS(__), simulationSettingsOpt = sopt) then
  let dirExtra = if modelInfo.directory then '-L"<%modelInfo.directory%>"' //else ""
  let libsStr = (makefileParams.libs |> lib => lib ;separator=" ")
  let libsPos1 = if not dirExtra then libsStr //else ""
  let libsPos2 = if dirExtra then libsStr // else ""
  let extraCflags = match sopt case SOME(s as SIMULATION_SETTINGS(__)) then
    '<%if s.measureTime then "-D_OMC_MEASURE_TIME "%> <%match s.method
       case "inline-euler" then "-D_OMC_INLINE_EULER"
       case "inline-rungekutta" then "-D_OMC_INLINE_RK"%> -D_OMC_OMPD_LIB -D_OMC_OMPD_MAIN'
  <<
  # Makefile generated by OpenModelica
  
  # Simulations use -O3 by default
  SIM_OR_DYNLOAD_OPT_LEVEL=
  CC=<%makefileParams.ccompiler%>
  CXX=<%makefileParams.cxxcompiler%>
  LINK=<%makefileParams.linker%>
  EXEEXT=<%makefileParams.exeext%>
  DLLEXT=<%makefileParams.dllext%>
  CFLAGS_BASED_ON_INIT_FILE=<%extraCflags%>
  CFLAGS=$(CFLAGS_BASED_ON_INIT_FILE) -I"<%makefileParams.omhome%>/include/omc" <%makefileParams.cflags%> -D_OMC_QSS -g -D_OMC_OMPD
  LDFLAGS=-L"<%makefileParams.omhome%>/lib/omc" <%makefileParams.ldflags%>
  SENDDATALIBS=<%makefileParams.senddatalibs%>
  PERL=perl
  
  .PHONY: <%fileNamePrefix%>
  <%fileNamePrefix%>: <%fileNamePrefix%>.conv.cpp model_functions.cpp model_functions.h model_records.c
  <%\t%> $(CXX) -I. -o <%fileNamePrefix%>$(EXEEXT) <%fileNamePrefix%>.conv.cpp model_functions.cpp <%dirExtra%> <%libsPos1%> <%libsPos2%> -lsim_ompd -linteractive $(CFLAGS) $(SENDDATALIBS) $(LDFLAGS) <%match System.os() case "OSX" then "-lf2c" else "-Wl,-Bstatic -lf2c -Wl,-Bdynamic"%> model_records.c 
  <%fileNamePrefix%>.conv.cpp: modelica_funcs.cpp
  <%\t%> $(PERL) <%makefileParams.omhome%>/share/omc/scripts/convert_lines.pl $< $@.tmp
  <%\t%> @mv $@.tmp $@
  >>
end simulationMakefile;


template simulationFileHeader(SimCode simCode)
 "Generates header part of simulation file."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__), extObjInfo=EXTOBJINFO(__)) then
  <<
  // Simulation code for <%SimCodeC.dotPath(modelInfo.name)%> generated by the OpenModelica Compiler <%getVersionNr()%>.
  
  #include "modelica.h"
  #include "assert.h"
  #include "string.h"
  #include "simulation_runtime.h"
  
  #include "model_functions.h"
  
  >>
end simulationFileHeader;

template simulationFunctionsFile(String filePrefix, list<Function> functions, list<Exp> literals)
 "Generates the content of the C file for functions in the simulation case."
::=
  <<
  #include "model_functions.h"
  extern "C" {
  
  <%literals |> literal hasindex i0 fromindex 0 => SimCodeC.literalExpConst(literal,i0) ; separator="\n"%>
  <%SimCodeC.functionBodies(functions)%>
  }
  
  >>
  /* adpro: leave a newline at the end of file to get rid of warnings! */
end simulationFunctionsFile;

template generateIncidenceMatrix(list<list<Integer>> conns)
"Generate the incidence matrix for the stand alone solver"
::=
  <<
  int incidenceRows = <% listLength(conns) %>;
  int incidenceMatrix[] = { <% conns |> c =>
  <<
  <% listNth(c,0) %>,<% listNth(c,2) %>
  >>
  ;separator="," %> }; 
  >>
end generateIncidenceMatrix;

template generateInputVars(list<Integer> vars_tuple)
"Generate the input vars for the stand alone solver"
::=
  <<
  int inputMatrix[] = { <% vars_tuple |> i => 
  << 
  <% i %>
  >>
  ; separator="," %> };
  int inputRows = <% intDiv(listLength(vars_tuple),2) %>;
  >>
end generateInputVars;

template generateOutputVars(list<Integer> vars_tuple)
"Generate the output vars for the stand alone solver"
::=
  <<
  int outputMatrix[] = { <% vars_tuple |> i => 
  << 
  <% i %>
  >>
  ; separator="," %> };
  int outputRows = <% intDiv(listLength(vars_tuple),2) %>;
  >>
end generateOutputVars;

end SimCodeQSS;

// vim: filetype=susan sw=2 sts=2
