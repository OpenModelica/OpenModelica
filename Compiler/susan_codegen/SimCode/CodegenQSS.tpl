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
  let()= textFile(simulationFile(simCode,qssInfo,guid), 'modelica_funcs.cpp')
  let()= textFile(simulationFunctionsHeaderFile(fileNamePrefix, modelInfo.functions, recordDecls), 'model_functions.h')
  let()= textFile(simulationFunctionsFile(fileNamePrefix, modelInfo.functions, literals), 'model_functions.c')
  let()= textFile(recordsFile(fileNamePrefix, recordDecls), 'model_records.c')
  let()= textFile(simulationMakefile(simCode), '<%fileNamePrefix%>.makefile')
  let()= textFile(structureFile(simCode,qssInfo), 'modelica_structure.pds')
  if simulationSettingsOpt then //tests the Option<> for SOME()
     let()= textFile(simulationInitFile(simCode,guid), 'model_init.xml')
     "" //empty result for true case 
  //else "" //the else is automatically empty, too
  //this top-level template always returns an empty result 
  //since generated texts are written to files directly
end translateModel;

template simulationFile(SimCode simCode, QSSinfo qssInfo, String guid)
 "Generates code for main C file for simulation target."
::=
match simCode
case SIMCODE(modelInfo=modelInfo as MODELINFO(varInfo=varInfo as  VARINFO(__))) then
  <<

  <%simulationFileHeader(simCode)%>
  #include "model_functions.c"
  #define _OMC_SEED_HACK
  #define _OMC_SEED_HACK_2
  #ifdef __cplusplus
  extern "C" {
  #endif

  #ifdef _OMC_QSS
  extern "C" { // adrpo: this is needed for Visual C++ compilation to work!
    const char *model_name="<%dotPath(modelInfo.name)%>";
    const char *model_fileprefix="model";
    const char *model_dir="<%modelInfo.directory%>";
  }
  #endif
 

  <%globalData(modelInfo,fileNamePrefix,guid)%>

  <%equationInfo(appendLists(appendAllequations(jacobianMatrixes),allEquations))%>

  <%functionInitialResidual(residualEquations)%>

  <%functionExtraResiduals(allEquations)%>

  <%externalFunctionIncludes(externalFunctionIncludes)%>

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
  
  <%functionSetLocalData()%>
  
  <%functionInitializeDataStruc()%>

  <%functionCallExternalObjectConstructors(extObjInfo)%>
  
  <%functionDeInitializeDataStruc(extObjInfo)%>
  
  <%functionInput(modelInfo)%>
  
  <%functionOutput(modelInfo)%>

  <%functionInitSample(sampleConditions)%>
  
  <%functionSampleEquations(sampleEquations)%>

  <%functionStoreDelayed(delayedExps)%>

  <%functionInitial(startValueEquations)%>
  
  <%functionBoundParameters(parameterEquations)%>
  
  <%functionODE(odeEquations,"")%>
  
  <%functionAlgebraic(algebraicEquations)%>
    
  <%functionAliasEquation(removedEquations)%>
                       
  <%functionDAE(allEquations, whenClauses, helpVarInfo)%>
    
  <%functionOnlyZeroCrossing(zeroCrossings)%>
  
  <%functionCheckForDiscreteChanges(discreteModelVars)%>
    
  <%generateLinearMatrixes(jacobianMatrixes)%>
  
  <%functionlinearmodel(modelInfo)%>
  
  <%\n%> 

  }
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
    let e1 = daeExp(start, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let e2 = daeExp(interval, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/)
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
  let exp = daeExp(right, contextSimulationDiscrete, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    <<
    <% cref(left) %>  = <% exp %>;
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
    let val = daeExp(value, contextSimulationDiscrete, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  <<
  <% cref(stateVar) %> = <% val %>; // Reinit of var <% cref(stateVar) %> 
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
  let helpInit = daeExp(e, contextSimulationDiscrete, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let &preExp += <<localData->helpVars[<%hvar%>] = <% helpInit %>;

    >>
  'localData->helpVars[<%hvar%>] && !localData->helpVars_saved[<%hvar%>] /* edge */'
    ;separator=" || ")
end functionPreWhenCondition;

template functionQssStaticBlocks(list<list<SimEqSystem>> derivativEquations,list<ZeroCrossing> zeroCrossings, QSSinfo qssInfo, Integer nStates)
  "Generates function in simulation file."
::=
    match qssInfo
    case BackendQSS.QSSINFO(__) then
      let &varDecls = buffer "" /*BUFD*/
    let &tmp = buffer ""
        let numStatic = intAdd(listLength(eqs),listLength(zeroCrossings))
        let numPureStatic = listLength(eqs)
        let numZeroCross = listLength(zeroCrossings)
        let staticFun = generateStaticFunc(derivativEquations,zeroCrossings,varDecls,DEVSstructure,eqs,outVarLst,nStates,tmp)
        let zeroCross = generateZeroCrossingsEq(listLength(eqs),zeroCrossings,varDecls,DEVSstructure,outVarLst,nStates)

  <<
  int staticBlocks = <% numStatic %>;
  int staticPureBlocks = <% numPureStatic %>;
  int zeroCrossings = <% numZeroCross %>;

  <%tmp%>
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
    out[<% i0 %>] =  <% BackendQSS.derPrefix(listNth(varLst,intAdd(i,-1)))%><% cref(BackendVariable.varCref(listNth(varLst,intAdd(i,-1)))) %>;
    >>
    ; separator="\n")
end generateOutputs;


template generateInputs(BackendQSS.DevsStruct devsst, Integer index, list<BackendDAE.Var> varLst, Integer nStates)
"Generate inputs for static blocks"
::= 
    (BackendQSS.getInputs(devsst,index) |> i hasindex i0 =>
    <<
    // Input <% i0 %> is var <% i %>
    <% cref(BackendVariable.varCref(listNth(varLst,intAdd(i,-1)))) %> = in[<% i0 %>];
    >>
    ; separator="\n")
end generateInputs;

template generateStaticFunc(list<list<SimEqSystem>> odeEq,list<ZeroCrossing> zeroCrossings, 
    Text &varDecls /*BUFP*/, BackendQSS.DevsStruct devsst,list<list<SimCode.SimEqSystem>> BLTblocks, list<BackendDAE.Var> varLst, Integer nStates, Text &tmp)
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
      <%  (eqs |> eq => equation_(BackendQSS.replaceZC(eq,zeroCrossings), contextSimulationNonDiscrete, &varDecls, &tmp ); separator="\n")  %>

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
    let e1 = daeExp(exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let e2 = daeExp(exp2, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let sub = generateRelation(operator,e1,e2)
  <<
  <% sub %>
  >>
  case e as CALL(path=IDENT(name="sample")) then
  <<
  >>
  else error(sourceInfo(), 'Unhandled expression in SimCodeQSS.generateZCExp: <%ExpressionDump.printExpStr(exp)%>')
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
        let expPart = daeExp(exp, contextSimulationDiscrete, &preDisc /* BUFC */, &varDecls /* BUFD */)
    <<
    <%preDisc%>
    <%cref(cref)%> = <%expPart%>;
    >>
    ;separator="\n")
    <<
    <%disc%>
    >>

  /*
    case SES_SIMPLE_ASSIGN(__) then
      let &preDisc = buffer "" /*BUFD*/
        let expPart = daeExp(exp, contextSimulationDiscrete, &preDisc /* BUFC */, &varDecls /* BUFD */)
    <<
    <%preDisc%>
    <%cref(cref)%> = <%expPart%>;
    >>
    */
    case _ then ''
end generateDiscUpdate;


template generateIntegrators(Integer nStates)
"Function to generate the integrator atomics for the DEVS structure"
::= 
    (fill(0,nStates) |> i hasindex i0 =>
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
      Path = modelica/modelica_qss_static.h // Crossing function <%i0%> for <% daeExp(relation_, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/) %>
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
      Path = modelica/modelica_qss_cross_detect.h // Crossing detector <%i0%> for <% daeExp(relation_, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/) %>
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
    let e1 = daeExp(start, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let e2 = daeExp(interval, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/)
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
    return  <% cref(BackendVariable.varCref(var)) %>;
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
  LDFLAGS=-L"<%makefileParams.omhome%>/lib/omc" -lSimulationRuntimeQss <%makefileParams.ldflags%>
  SENDDATALIBS=<%makefileParams.senddatalibs%>
  PERL=perl
  
  .PHONY: <%fileNamePrefix%>
  <%fileNamePrefix%>: <%fileNamePrefix%>.conv.cpp model_functions.c model_functions.h model_records.c
  <%\t%> $(CXX) -I. -o <%fileNamePrefix%>$(EXEEXT) <%fileNamePrefix%>.conv.cpp model_functions.c <%dirExtra%> <%libsPos1%> <%libsPos2%> $(CFLAGS) $(LDFLAGS) -linteractive $(SENDDATALIBS) <%match System.os() case "OSX" then "-lf2c" else "-Wl,-Bstatic -lf2c -Wl,-Bdynamic"%> model_records.c 
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
  // Simulation code for <%dotPath(modelInfo.name)%> generated by the OpenModelica Compiler <%getVersionNr()%>.
  
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
  
  <%literals |> literal hasindex i0 fromindex 0 => literalExpConst(literal,i0) ; separator="\n"%>
  <%functionBodies(functions)%>
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

template globalData(ModelInfo modelInfo, String fileNamePrefix, String guid)
 "Generates global data in simulation file."
::=
let () = System.tmpTickReset(1000)
match modelInfo
case MODELINFO(varInfo=VARINFO(__), vars=SIMVARS(__)) then
  <<
  #define MODEL_GUID  "{<%guid%>}" // to check if the init file match the model!
  #define NHELP <%varInfo.numHelpVars%> // number of helper vars
  #define NG <%varInfo.numZeroCrossings%> // number of zero crossings
  #define NG_SAM <%varInfo.numTimeEvents%> // number of zero crossings that are samples
  #define NX <%varInfo.numStateVars%>  // number of states
  #define NY <%varInfo.numAlgVars%>  // number of real variables
  #define NA <%varInfo.numAlgAliasVars%>  // number of alias variables
  #define NP <%varInfo.numParams%> // number of parameters
  #define NO <%varInfo.numOutVars%> // number of outputvar on topmodel
  #define NI <%varInfo.numInVars%> // number of inputvar on topmodel
  #define NR <%varInfo.numResiduals%> // number of residuals for initialialization function
  #define NEXT <%varInfo.numExternalObjects%> // number of external objects
  #define NFUNC <%listLength(functions)%> // number of functions used by the simulation
  #define MAXORD 5
  #define NYSTR <%varInfo.numStringAlgVars%> // number of alg. string variables
  #define NASTR <%varInfo.numStringAliasVars%> // number of alias string variables
  #define NPSTR <%varInfo.numStringParamVars%> // number of string parameters
  #define NYINT <%varInfo.numIntAlgVars%> // number of alg. int variables
  #define NAINT <%varInfo.numIntAliasVars%> // number of alias int variables
  #define NPINT <%varInfo.numIntParams%> // number of int parameters
  #define NYBOOL <%varInfo.numBoolAlgVars%> // number of alg. bool variables
  #define NABOOL <%varInfo.numBoolAliasVars%> // number of alias bool variables
  #define NPBOOL <%varInfo.numBoolParams%> // number of bool parameters
  #define NJACVARS <%varInfo.numJacobianVars%> // number of jacobian variables
  
  static DATA* localData = 0;
  #define time localData->timeValue
  #define $P$old$Ptime localData->oldTime
  #define $P$current_step_size globalData->current_stepsize

  #ifndef _OMC_QSS
  #ifdef __cplusplus
  extern "C" { // adrpo: this is needed for Visual C++ compilation to work!
  #endif
    const char *model_name="<%dotPath(name)%>";
    const char *model_fileprefix="<%fileNamePrefix%>";
    const char *model_dir="<%directory%>";
  #ifdef __cplusplus
  }
  #endif
  #endif
  
  <%globalDataVarInfoArray("state_names", vars.stateVars)%>
  <%globalDataVarInfoArray("derivative_names", vars.derivativeVars)%>
  <%globalDataVarInfoArray("algvars_names", vars.algVars)%>
  <%globalDataVarInfoArray("param_names", vars.paramVars)%>
  <%globalDataVarInfoArray("alias_names", vars.aliasVars)%>
  <%globalDataVarInfoArray("int_alg_names", vars.intAlgVars)%>
  <%globalDataVarInfoArray("int_param_names", vars.intParamVars)%>
  <%globalDataVarInfoArray("int_alias_names", vars.intAliasVars)%>
  <%globalDataVarInfoArray("bool_alg_names", vars.boolAlgVars)%>
  <%globalDataVarInfoArray("bool_param_names", vars.boolParamVars)%>
  <%globalDataVarInfoArray("bool_alias_names", vars.boolAliasVars)%>
  <%globalDataVarInfoArray("string_alg_names", vars.stringAlgVars)%>
  <%globalDataVarInfoArray("string_param_names", vars.stringParamVars)%>
  <%globalDataVarInfoArray("string_alias_names", vars.stringAliasVars)%>
  <%globalDataVarInfoArray("jacobian_names", vars.jacobianVars)%>
  <%globalDataFunctionInfoArray("function_names", functions)%>
  
  <%vars.stateVars |> var =>
    globalDataVarDefine(var, "states")
  ;separator="\n"%>
  <%vars.derivativeVars |> var =>
    globalDataVarDefine(var, "statesDerivatives")
  ;separator="\n"%>
  <%vars.algVars |> var =>
    globalDataVarDefine(var, "algebraics")
  ;separator="\n"%>
  <%vars.paramVars |> var =>
    globalDataVarDefine(var, "parameters")
  ;separator="\n"%>
  <%vars.extObjVars |> var =>
    globalDataVarDefine(var, "extObjs")
  ;separator="\n"%>
  <%vars.intAlgVars |> var =>
    globalDataVarDefine(var, "intVariables.algebraics")
  ;separator="\n"%>
  <%vars.intParamVars |> var =>
    globalDataVarDefine(var, "intVariables.parameters")
  ;separator="\n"%>
  <%vars.boolAlgVars |> var =>
    globalDataVarDefine(var, "boolVariables.algebraics")
  ;separator="\n"%>
  <%vars.boolParamVars |> var =>
    globalDataVarDefine(var, "boolVariables.parameters")
  ;separator="\n"%>  
  <%vars.stringAlgVars |> var =>
    globalDataVarDefine(var, "stringVariables.algebraics")
  ;separator="\n"%>
  <%vars.stringParamVars |> var =>
    globalDataVarDefine(var, "stringVariables.parameters")
  ;separator="\n"%>
  <%vars.jacobianVars |> var =>
    globalDataVarDefine(var, "jacobianVars")
  ;separator="\n"%>  
  <%functions |> fn hasindex i0 => '#define <%functionName(fn,false)%>_index <%i0%>'; separator="\n"%>
  
  void init_Alias(DATA* data)
  {
  <%globalDataAliasVarArray("DATA_REAL_ALIAS","omc__realAlias", vars.aliasVars)%>
  <%globalDataAliasVarArray("DATA_INT_ALIAS","omc__intAlias", vars.intAliasVars)%>
  <%globalDataAliasVarArray("DATA_BOOL_ALIAS","omc__boolAlias", vars.boolAliasVars)%>
  <%globalDataAliasVarArray("DATA_STRING_ALIAS","omc__stringAlias", vars.stringAliasVars)%>
  if (data->nAlias)
    memcpy(data->realAlias,omc__realAlias,sizeof(DATA_REAL_ALIAS)*data->nAlias);
  if (data->intVariables.nAlias)
    memcpy(data->intVariables.alias,omc__intAlias,sizeof(DATA_INT_ALIAS)*data->intVariables.nAlias);
  if (data->boolVariables.nAlias)
    memcpy(data->boolVariables.alias,omc__boolAlias,sizeof(DATA_BOOL_ALIAS)*data->boolVariables.nAlias);
  if (data->stringVariables.nAlias)
    memcpy(data->stringVariables.alias,omc__stringAlias,sizeof(DATA_STRING_ALIAS)*data->stringVariables.nAlias);  
  };
  
  static char init_fixed[NX+NX+NY+NYINT+NYBOOL+NP+NPINT+NPBOOL] = {
    <%{(vars.stateVars |> SIMVAR(__) =>
        '<%globalDataFixedInt(isFixed)%> /* <%crefStr(name)%> */'
      ;separator=",\n"),
      (vars.derivativeVars |> SIMVAR(__) =>
        '<%globalDataFixedInt(isFixed)%> /* <%crefStr(name)%> */'
      ;separator=",\n"),
      (vars.algVars |> SIMVAR(__) =>
        '<%globalDataFixedInt(isFixed)%> /* <%crefStr(name)%> */'
      ;separator=",\n"),
      (vars.intAlgVars |> SIMVAR(__) =>
        '<%globalDataFixedInt(isFixed)%> /* <%crefStr(name)%> */'
      ;separator=",\n"),
      (vars.boolAlgVars |> SIMVAR(__) =>
        '<%globalDataFixedInt(isFixed)%> /* <%crefStr(name)%> */'
      ;separator=",\n"),        
      (vars.paramVars |> SIMVAR(__) =>
        '<%globalDataFixedInt(isFixed)%> /* <%crefStr(name)%> */'
      ;separator=",\n"),
     (vars.intParamVars |> SIMVAR(__) =>
        '<%globalDataFixedInt(isFixed)%> /* <%crefStr(name)%> */'
      ;separator=",\n"),
     (vars.boolParamVars |> SIMVAR(__) =>
        '<%globalDataFixedInt(isFixed)%> /* <%crefStr(name)%> */'
      ;separator=",\n")}
    ;separator=",\n"%>
  };
  
  char hasNominalValue[NX+NY+NP] = {
    <%{(vars.stateVars |> SIMVAR(__) =>
        '<%globalDataHasNominalValue(nominalValue)%> /* <%crefStr(name)%> */'
      ;separator=",\n"),
      (vars.algVars |> SIMVAR(__) =>
        '<%globalDataHasNominalValue(nominalValue)%> /* <%crefStr(name)%> */'
      ;separator=",\n"),      
      (vars.paramVars |> SIMVAR(__) =>
        '<%globalDataHasNominalValue(nominalValue)%> /* <%crefStr(name)%> */'
      ;separator=",\n")}
    ;separator=",\n"%>
  };
  
  double nominalValue[NX+NY+NP] = {
    <%{(vars.stateVars |> SIMVAR(__) =>
        '<%globalDataNominalValue(nominalValue)%> /* <%crefStr(name)%> */'
      ;separator=",\n"),
      (vars.algVars |> SIMVAR(__) =>
        '<%globalDataNominalValue(nominalValue)%> /* <%crefStr(name)%> */'
      ;separator=",\n"),      
      (vars.paramVars |> SIMVAR(__) =>
        '<%globalDataNominalValue(nominalValue)%> /* <%crefStr(name)%> */'
      ;separator=",\n")}
    ;separator=",\n"%>
  };
  
  char var_attr[NX+NY+NYINT+NYBOOL+NYSTR+NP+NPINT+NPBOOL+NPSTR] = {
    <%{(vars.stateVars |> SIMVAR(__) =>
        '<%globalDataAttrInt(type_)%>+<%globalDataDiscAttrInt(isDiscrete)%> /* <%crefStr(name)%> */'
      ;separator=",\n"),
      (vars.algVars |> SIMVAR(__) =>
        '<%globalDataAttrInt(type_)%>+<%globalDataDiscAttrInt(isDiscrete)%> /* <%crefStr(name)%> */'
      ;separator=",\n"),
      (vars.intAlgVars |> SIMVAR(__) =>
        '<%globalDataAttrInt(type_)%>+<%globalDataDiscAttrInt(isDiscrete)%> /* <%crefStr(name)%> */'
      ;separator=",\n"),
      (vars.boolAlgVars |> SIMVAR(__) =>
        '<%globalDataAttrInt(type_)%>+<%globalDataDiscAttrInt(isDiscrete)%> /* <%crefStr(name)%> */'
      ;separator=",\n"),
      (vars.stringAlgVars |> SIMVAR(__) =>
        '<%globalDataAttrInt(type_)%>+<%globalDataDiscAttrInt(isDiscrete)%> /* <%crefStr(name)%> */'
      ;separator=",\n"),      
      (vars.paramVars |> SIMVAR(__) =>
        '<%globalDataAttrInt(type_)%>+<%globalDataDiscAttrInt(isDiscrete)%> /* <%crefStr(name)%> */'
       ;separator=",\n"),
      (vars.intParamVars |> SIMVAR(__) =>
        '<%globalDataAttrInt(type_)%>+<%globalDataDiscAttrInt(isDiscrete)%> /* <%crefStr(name)%> */'
       ;separator=",\n"),
      (vars.boolParamVars |> SIMVAR(__) =>
        '<%globalDataAttrInt(type_)%>+<%globalDataDiscAttrInt(isDiscrete)%> /* <%crefStr(name)%> */'
       ;separator=",\n"),
      (vars.stringParamVars |> SIMVAR(__) =>
        '<%globalDataAttrInt(type_)%>+<%globalDataDiscAttrInt(isDiscrete)%> /* <%crefStr(name)%> */'
       ;separator=",\n") }
    ;separator=",\n"%>
  };
  >>
end globalData;


template globalDataVarInfoArray(String _name, list<SimVar> items)
 "Generates array with variable names in global data section."
::=
  match items
  case {} then
    <<
    const struct omc_varInfo <%_name%>[1] = {{-1,"","",omc_dummyFileInfo}};
    >>
  case items then
    <<
    const struct omc_varInfo <%_name%>[<%listLength(items)%>] = {
      <%items |> var as SIMVAR(source=SOURCE(info=info as INFO(__))) => '{<%System.tmpTick()%>,"<%escapedString(crefStr(var.name))%>","<%Util.escapeModelicaStringToCString(var.comment)%>",{<%infoArgs(info)%>}}'; separator=",\n"%>
    };
    <%items |> var as SIMVAR(source=SOURCE(info=info as INFO(__))) hasindex i0 => '#define <%cref(var.name)%>__varInfo <%_name%>[<%i0%>]'; separator="\n"%>
    >>
end globalDataVarInfoArray;

template globalDataFunctionInfoArray(String name, list<Function> items)
 "Generates array with variable names in global data section."
::=
  match items
  case {} then
    <<
    const struct omc_functionInfo <%name%>[1] = {{-1,"",omc_dummyFileInfo}};
    >>
  case items then
    <<
    const struct omc_functionInfo <%name%>[<%listLength(items)%>] = {
      <%items |> fn => '{<%System.tmpTick()%>,"<%functionName(fn,true)%>",{<%infoArgs(functionInfo(fn))%>}}'; separator=",\n"%>
    };
    >>
end globalDataFunctionInfoArray;

template globalDataVarDefine(SimVar simVar, String arrayName)
 "Generates a define statement for a varable in the global data section."
::=
match arrayName
case "jacobianVars" then
  match simVar
  case SIMVAR(aliasvar=NOALIAS()) then
    <<
    #define <%cref(name)%> localData-><%arrayName%>[<%index%>]
    >> 
  end match
case _ then
  match simVar
  case SIMVAR(arrayCref=SOME(c),aliasvar=NOALIAS()) then
    <<
    #define <%cref(c)%> localData-><%arrayName%>[<%index%>]
    #define $P$PRE<%cref(c)%> localData-><%arrayName%>_saved[<%index%>]
    #define <%cref(name)%> localData-><%arrayName%>[<%index%>]
    #define $P$old<%cref(name)%> localData-><%arrayName%>_old[<%index%>]
    #define $P$old2<%cref(name)%> localData-><%arrayName%>_old2[<%index%>]
    #define $P$PRE<%cref(name)%> localData-><%arrayName%>_saved[<%index%>]
    >>
  case SIMVAR(aliasvar=NOALIAS()) then
    <<
    #define <%cref(name)%> localData-><%arrayName%>[<%index%>]
    #define $P$old<%cref(name)%> localData-><%arrayName%>_old[<%index%>]
    #define $P$old2<%cref(name)%> localData-><%arrayName%>_old2[<%index%>]
    #define $P$PRE<%cref(name)%> localData-><%arrayName%>_saved[<%index%>]
    >>  
end globalDataVarDefine;

template globalDataAliasVarArray(String _type, String _name, list<SimVar> items)
 "Generates array with variable names in global data section."
::=
  match items
  case {} then
    <<
      <%_type%> <%_name%>[1] = {{0,0,-1}};
    >>
  case items then
    <<
      <%_type%> <%_name%>[<%listLength(items)%>] = {
        <%items |> var as SIMVAR(__) => '{<%aliasVarNameType(aliasvar)%>,<%index%>}'; separator=",\n"%>
      };
    >>
end globalDataAliasVarArray;

template equationInfo(list<SimEqSystem> eqs)
::=
  match eqs
  case {} then "const struct omc_equationInfo equation_info[1] = {{0,NULL}};"
  else
    let &preBuf = buffer ""
    let res =
    <<
    const int nEquation = <%listLength(eqs)%>;
    const struct omc_equationInfo equation_info[<%listLength(eqs)%>] = {
      <% eqs |> eq hasindex i0 =>
        <<{<%System.tmpTick()%>,<%match eq
          case SES_RESIDUAL(__) then '"SES_RESIDUAL <%i0%>",0,NULL'
          case SES_SIMPLE_ASSIGN(__) then
            let var = '<%cref(cref)%>__varInfo'
            let &preBuf += 'const struct omc_varInfo *equationInfo_cref<%i0%> = &<%var%>;<%\n%>'
            '"SES_SIMPLE_ASSIGN <%i0%>",1,&equationInfo_cref<%i0%>'
          case SES_ARRAY_CALL_ASSIGN(__) then
            //let var = '<%cref(componentRef)%>__varInfo'
            //let &preBuf += 'const struct omc_varInfo *equationInfo_cref<%i0%> = &<%var%>;'
            '"SES_ARRAY_CALL_ASSIGN <%i0%>",0,NULL'
          case SES_ALGORITHM(__) then '"SES_ALGORITHM <%i0%>",0,NULL'
          case SES_WHEN(__) then '"SES_WHEN <%i0%>",0,NULL'
          case SES_LINEAR(__) then '"LINEAR<%index%>",0,NULL'
          case SES_NONLINEAR(__) then
            let &preBuf += 'const struct omc_varInfo *residualFunc<%index%>_crefs[<%listLength(crefs)%>] = {<%crefs|>cr=>'&<%cref(cr)%>__varInfo'; separator=","%>};'
            '"residualFunc<%index%>",<%listLength(crefs)%>,residualFunc<%index%>_crefs'
          case SES_MIXED(__) then '"MIXED<%index%>",0,NULL'
          else '"unknown equation <%i0%>",0,NULL'%>}
        >> ; separator=",\n"%>
    };
    >>
    <<
    <%preBuf%>
    <%res%>
    <% eqs |> eq hasindex i0 => match eq
      case SES_MIXED(__)
      case SES_LINEAR(__)
      case SES_NONLINEAR(__) then '#define SIM_PROF_EQ_<%index%> <%i0%>'
    ; separator="\n"
    %>
    const int n_omc_equationInfo_reverse_prof_index = 0<% eqs |> eq hasindex i0 => match eq
        case SES_MIXED(__)
        case SES_LINEAR(__)
        case SES_NONLINEAR(__) then '+1'
      %>;
    const int omc_equationInfo_reverse_prof_index[] = {
      <% eqs |> eq hasindex i0 => match eq
        case SES_MIXED(__)
        case SES_LINEAR(__)
        case SES_NONLINEAR(__) then '<%i0%>,<%\n%>'
      ; empty
      %>
    };
    <% eqs |> eq hasindex i0 => match eq
      case SES_MIXED(__)
      case SES_LINEAR(__)
      case SES_NONLINEAR(__) then '#define SIM_PROF_EQ_<%index%> <%i0%>'
    ; separator="\n"
    %>
    >>
end equationInfo;

template functionSetLocalData()
 "Generates function in simulation file."
::=
  <<
  void setLocalData(DATA* data)
  {
    localData = data;
    init_Alias(data);
  }
  >>
end functionSetLocalData;


template functionInitializeDataStruc()
 "Generates function in simulation file."
::=
  <<
  DATA* initializeDataStruc()
  {  
    DATA* returnData = (DATA*)malloc(sizeof(DATA));
  
    if(!returnData) //error check
      return 0;
  
    memset(returnData,0,sizeof(DATA));
    returnData->nStates = NX;
    returnData->nAlgebraic = NY;
    returnData->nAlias = NA;
    returnData->nParameters = NP;
    returnData->nInputVars = NI;
    returnData->nOutputVars = NO;
    returnData->nFunctions = NFUNC;
    returnData->nEquations = nEquation;
    returnData->nProfileBlocks = n_omc_equationInfo_reverse_prof_index;
    returnData->nZeroCrossing = NG;
    returnData->nRawSamples = NG_SAM;
    returnData->nInitialResiduals = NR;
    returnData->nHelpVars = NHELP;
    returnData->stringVariables.nParameters = NPSTR;
    returnData->stringVariables.nAlgebraic = NYSTR;
    returnData->stringVariables.nAlias = NASTR;
    returnData->intVariables.nParameters = NPINT;
    returnData->intVariables.nAlgebraic = NYINT;
    returnData->intVariables.nAlias = NAINT;
    returnData->boolVariables.nParameters = NPBOOL;
    returnData->boolVariables.nAlgebraic = NYBOOL;
    returnData->boolVariables.nAlias = NABOOL;
    returnData->nJacobianvars = NJACVARS;
  
    returnData->initFixed = init_fixed;
    returnData->var_attr = var_attr;
    returnData->modelName = model_name;
    returnData->modelFilePrefix = model_fileprefix;
    returnData->modelGUID = MODEL_GUID;
    returnData->statesNames = state_names;
    returnData->stateDerivativesNames = derivative_names;
    returnData->algebraicsNames = algvars_names;
    returnData->int_alg_names = int_alg_names;
    returnData->bool_alg_names = bool_alg_names;
    returnData->string_alg_names = string_alg_names;
    returnData->parametersNames = param_names;
    returnData->int_param_names = int_param_names;
    returnData->bool_param_names = bool_param_names;
    returnData->string_param_names = string_param_names;
    returnData->alias_names = alias_names;
    returnData->int_alias_names = int_alias_names;
    returnData->bool_alias_names = bool_alias_names;
    returnData->string_alias_names = string_alias_names;
    returnData->jacobian_names = jacobian_names;
    returnData->functionNames = function_names;
    returnData->equationInfo = equation_info;
    returnData->equationInfo_reverse_prof_index = omc_equationInfo_reverse_prof_index;
    
    if (NEXT) {
      returnData->extObjs = (void**)malloc(sizeof(void*)*NEXT);
      if (!returnData->extObjs) {
        printf("error allocating external objects\n");
        exit(-2);
      }
      memset(returnData->extObjs,0,sizeof(void*)*NEXT);
    } else {
      returnData->extObjs = 0;
    }
  
    return returnData;
  }
  
  >>
end functionInitializeDataStruc;

template functionCallExternalObjectConstructors(ExtObjInfo extObjInfo)
 "Generates function in simulation file."
::=
match extObjInfo
case EXTOBJINFO(__) then
  let &funDecls = buffer "" /*BUFD*/
  let &varDecls = buffer "" /*BUFD*/
  let ctorCalls = (vars |> var as SIMVAR(initialValue=SOME(exp)) =>
      let &preExp = buffer "" /*BUFD*/
      let arg = daeExp(exp, contextOther, &preExp, &varDecls)
      /* Restore the memory state after each object has been initialized. Then we can
       * initalize a really large number of external objects that play with strings :)
       */
      <<
      <%preExp%>
      <%cref(var.name)%> = <%arg%>;
      restore_memory_state(mem_state);
      >>
    ;separator="\n")
  <<
  /* Has to be performed after _init.xml file has been read */
  void callExternalObjectConstructors(DATA* localData) {
    <%varDecls%>
    state mem_state;
    mem_state = get_memory_state();
    <%ctorCalls%>
    <%aliases |> (var1, var2) => '<%cref(var1)%> = <%cref(var2)%>;' ;separator="\n"%>
  }

  >>
end functionCallExternalObjectConstructors;


template functionDeInitializeDataStruc(ExtObjInfo extObjInfo)
 "Generates function in simulation file."
::=
match extObjInfo
case extObjInfo as EXTOBJINFO(__) then
  <<
  void deInitializeDataStruc(DATA* data)
  {
    if (data->extObjs) {
      <%extObjInfo.vars |> var as SIMVAR(varKind=ext as EXTOBJ(__)) => '_<%underscorePath(ext.fullClassName)%>_destructor(<%cref(var.name)%>);' ;separator="\n"%>
      free(data->extObjs);
      data->extObjs = 0;
    }
  }
  >>
end functionDeInitializeDataStruc;


template functionInput(ModelInfo modelInfo)
 "Generates function in simulation file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<
  int input_function()
  {
    <%vars.inputVars |> SIMVAR(__) hasindex i0 =>
      '<%cref(name)%> = localData->inputVars[<%i0%>];'
    ;separator="\n"%>
    return 0;
  }
  >>
end functionInput;


template functionOutput(ModelInfo modelInfo)
 "Generates function in simulation file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<
  int output_function()
  {
    <%vars.outputVars |> SIMVAR(__) hasindex i0 =>
      'localData->outputVars[<%i0%>] = <%cref(name)%>;'
    ;separator="\n"%>
    return 0;
  }
  >>
end functionOutput;

template functionInitSample(list<SampleCondition> sampleConditions)
  "Generates function initSample() in simulation file."
::=
  let &varDecls = buffer "" /*BUFD*/
  let timeEventCode = timeEventsTpl(sampleConditions, &varDecls /*BUFD*/)
  <<
  /* Initializes the raw time events of the simulation using the now
     calcualted parameters. */
  void function_sampleInit()
  {
    <%if timeEventCode then "int i = 0; // Current index"%>
    <%timeEventCode%>
  }
  >>
end functionInitSample;

template functionSampleEquations(list<SimEqSystem> sampleEqns)
 "Generates function for sample equations."
::=
  let &varDecls = buffer "" /*BUFD*/
  let &tmp = buffer ""
  let eqs = (sampleEqns |> eq =>
      equation_(eq, contextSimulationDiscrete, &varDecls /*BUFD*/, &tmp)
    ;separator="\n")
  <<
  <%&tmp%>
  int function_updateSample()
  {
    state mem_state;
    <%varDecls%>
  
    mem_state = get_memory_state();
    <%eqs%>
    restore_memory_state(mem_state);
  
    return 0;
  }
>>
end functionSampleEquations;

template functionInitial(list<SimEqSystem> startValueEquations)
 "Generates function in simulation file."
::=
  let &varDecls = buffer "" /*BUFD*/
  let &tmp = buffer ""
  let eqPart = (startValueEquations |> eq as SES_SIMPLE_ASSIGN(__) =>
      equation_(eq, contextOther, &varDecls /*BUFD*/, &tmp)
    ;separator="\n")
  <<
  <%&tmp%>
  int initial_function()
  {
    <%varDecls%>
  
    <%eqPart%>
  
    <%startValueEquations |> SES_SIMPLE_ASSIGN(__) =>
      'if (sim_verbose >= LOG_INIT) { printf("Setting variable start value: %s(start=%f)\n", "<%cref(cref)%>", (<%crefType(cref)%>) <%cref(cref)%>); }'
    ;separator="\n"%>
  
    return 0;
  }
  >>
end functionInitial;


template functionInitialResidual(list<SimEqSystem> residualEquations)
 "Generates function in simulation file."
::=
  let &varDecls = buffer "" /*BUFD*/
  let body = (residualEquations |> SES_RESIDUAL(__) =>
      match exp 
      case DAE.SCONST(__) then
        'localData->initialResiduals[i++] = 0;'
      else
        let &preExp = buffer "" /*BUFD*/
        let expPart = daeExp(exp, contextOther, &preExp /*BUFC*/,
                           &varDecls /*BUFD*/)
        '<%preExp%>localData->initialResiduals[i++] = <%expPart%>;
if (sim_verbose == LOG_RES_INIT) { printf(" Residual[%d] : <%ExpressionDump.printExpStr(exp)%> = %f\n",i,localData->initialResiduals[i-1]); }'
    ;separator="\n")
  <<
  int initial_residual(double $P$_lambda)
  {
    int i = 0;
    state mem_state;
    <%varDecls%>
  
    mem_state = get_memory_state();
    <%body%>
    restore_memory_state(mem_state);
  
    return 0;
  }
  >>
end functionInitialResidual;


template functionExtraResiduals(list<SimEqSystem> allEquations)
 "Generates functions in simulation file."
::=
  (allEquations |> eqn => (match eqn
     case eq as SES_MIXED(__) then functionExtraResiduals(fill(eq.cont,1))
     case eq as SES_NONLINEAR(__) then
     let &varDecls = buffer "" /*BUFD*/
     let &tmp = buffer ""
     let algs = (eq.eqs |> eq2 as SES_ALGORITHM(__) =>
         equation_(eq2, contextSimulationDiscrete, &varDecls /*BUFD*/, &tmp)
       ;separator="\n")      
     let prebody = (eq.eqs |> eq2 as SES_SIMPLE_ASSIGN(__) =>
         equation_(eq2, contextOther, &varDecls /*BUFD*/, &tmp)
       ;separator="\n")   
     let body = (eq.eqs |> eq2 as SES_RESIDUAL(__) hasindex i0 =>
         let &preExp = buffer "" /*BUFD*/
         let expPart = daeExp(eq2.exp, contextSimulationDiscrete,
                            &preExp /*BUFC*/, &varDecls /*BUFD*/)
         '<%preExp%>res[<%i0%>] = <%expPart%>;'
       ;separator="\n")
     <<
     <%&tmp%>
     void residualFunc<%index%>(int *n, double* xloc, double* res, int* iflag)
     {
       state mem_state;
       <%varDecls%>
       #ifdef _OMC_MEASURE_TIME
       SIM_PROF_ADD_NCALL_EQ(SIM_PROF_EQ_<%index%>,1);
       #endif
       mem_state = get_memory_state();
       <%algs%>
       <%prebody%>
       <%body%>
       restore_memory_state(mem_state);
     }
     >>
   )
   ;separator="\n\n")
end functionExtraResiduals;


template functionBoundParameters(list<SimEqSystem> parameterEquations)
 "Generates function in simulation file."
::=
  let () = System.tmpTickReset(0)
  let &varDecls = buffer "" /*BUFD*/
  let &tmp = buffer ""
  let body = (parameterEquations |> eq as SES_SIMPLE_ASSIGN(__) =>
      equation_(eq, contextOther, &varDecls /*BUFD*/, &tmp)
    ;separator="\n")
  let divbody = (parameterEquations |> eq as SES_ALGORITHM(__) =>
      equation_(eq, contextOther, &varDecls /*BUFD*/, &tmp)
    ;separator="\n")    
  <<
  <%&tmp%>
  int bound_parameters()
  {
    state mem_state;
    <%varDecls%>
  
    mem_state = get_memory_state();
    <%body%>
    <%divbody%>
    restore_memory_state(mem_state);
  
    return 0;
  }
  >>
end functionBoundParameters;

template functionStoreDelayed(DelayedExpression delayed)
  "Generates function in simulation file."
::=
  let &varDecls = buffer "" /*BUFD*/
  let storePart = (match delayed case DELAYED_EXPRESSIONS(__) then (delayedExps |> (id, e) =>
      let &preExp = buffer "" /*BUFD*/
      let eRes = daeExp(e, contextSimulationNonDiscrete,
                      &preExp /*BUFC*/, &varDecls /*BUFD*/)
      <<
      <%preExp%>
      storeDelayedExpression(<%id%>, <%eRes%>);<%\n%>
      >>
    ))
  <<
  int numDelayExpressionIndex = <%match delayed case DELAYED_EXPRESSIONS(__) then maxDelayedIndex%>;
  int function_storeDelayed()
  {
    state mem_state;
    <%varDecls%>

    mem_state = get_memory_state();
    <%storePart%>
    restore_memory_state(mem_state);

    return 0;
  }
  >>
end functionStoreDelayed;

template functionWhenReinitStatement(WhenOperator reinit, Text &varDecls /*BUFP*/)
 "Generates re-init statement for when equation."
::=
match reinit
case REINIT(__) then
  let &preExp = buffer "" /*BUFD*/
  let val = daeExp(value, contextSimulationDiscrete,
                 &preExp /*BUFC*/, &varDecls /*BUFD*/)
  <<
  <%preExp%>  <%cref(stateVar)%> = <%val%>;
  >>
case TERMINATE(__) then 
  let &preExp = buffer "" /*BUFD*/
  let msgVar = daeExp(message, contextSimulationDiscrete, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  <<
  <%preExp%>  MODELICA_TERMINATE(<%msgVar%>);
  >>
case ASSERT(source=SOURCE(info=info)) then
  assertCommon(condition, message, contextSimulationDiscrete, &varDecls, info)
end functionWhenReinitStatement;

template externalFunctionIncludes(list<String> includes)
 "Generates external includes part in function files."
::=
  if includes then
  <<
  #ifdef __cplusplus
  extern "C" {
  #endif
  <% (includes ;separator="\n") %>
  #ifdef __cplusplus
  }
  #endif
  >>
end externalFunctionIncludes;

template functionODE(list<list<SimEqSystem>> derivativEquations, Text method)
 "Generates function in simulation file."
::=
  let () = System.tmpTickReset(0)
  let funcs = derivativEquations |> eqs hasindex i1 fromindex 0 => functionODE_system(eqs,i1) ; separator="\n"
  let nFuncs = listLength(derivativEquations)
  let funcNames = derivativEquations |> eqs hasindex i1 fromindex 0 => 'functionODE_system<%i1%>' ; separator=",\n"
  let &varDecls2 = buffer "" /*BUFD*/
  let &tmp = buffer ""
  let stateContPartInline = (derivativEquations |> eqs => (eqs |> eq =>
      equation_(eq, contextInlineSolver, &varDecls2 /*BUFC*/, &tmp); separator="\n")
    ;separator="\n")
  <<
  <%tmp%>
  <%funcs%>
  static void (*functionODE_systems[<%nFuncs%>])(int) = {
    <%funcNames%>
  };
  
  void function_initMemoryState()
  {
    push_memory_states(<% if Flags.isSet(Flags.OPENMP) then noProc() else 1 %>);
  }
  
  int functionODE()
  {
    int id,th_id;
    state mem_state; /* We need to have separate memory pools for separate systems... */
    mem_state = get_memory_state();
    <% if Flags.isSet(Flags.OPENMP) then '#pragma omp parallel for private(id,th_id) schedule(<%match noProc() case 0 then "dynamic" else "static"%>)' %>
    for (id=0; id<<%nFuncs%>; id++) {
      th_id = omp_get_thread_num();
      functionODE_systems[id](th_id);
    }
    restore_memory_state(mem_state);
  
    return 0;
  }
  #include <simulation_inline_solver.h>
  const char *_omc_force_solver=_OMC_FORCE_SOLVER;
  const int inline_work_states_ndims=_OMC_SOLVER_WORK_STATES_NDIMS;
  <%match method
  case "inline-euler"
  case "inline-rungekutta" then
  <<
  // we need to access the inline define that we compiled the simulation with
  // from the simulation runtime.
  int functionODE_inline()
  {
    state mem_state;
    <%varDecls2%>
  
    mem_state = get_memory_state();
    begin_inline();
    <%stateContPartInline%>
    end_inline();
    restore_memory_state(mem_state);
  
    return 0;
  }
  >>
  else
  <<
  int functionODE_inline()
  {
    return 0;
  }
  >>
  %>
  >>
end functionODE;

template functionAlgebraic(list<SimEqSystem> algebraicEquations)
 "Generates function in simulation file."
::=
  let &varDecls = buffer "" /*BUFD*/
  let &tmp = buffer ""
  let algEquations = (algebraicEquations |> eq =>
      equation_(eq, contextSimulationNonDiscrete, &varDecls /*BUFC*/, &tmp)
    ;separator="\n")
  <<
  <%tmp%>
  /* for continuous time variables */
  int functionAlgebraics()
  {
    state mem_state;
    <%varDecls%>
  
    mem_state = get_memory_state();
    <%algEquations%>
    restore_memory_state(mem_state);
  
    return 0;
  }
  >>
end functionAlgebraic;

template functionAliasEquation(list<SimEqSystem> removedEquations)
 "Generates function in simulation file."
::=
  let &varDecls = buffer "" /*BUFD*/
  let &tmp = buffer ""
  let removedPart = (removedEquations |> eq =>
      equation_(eq, contextSimulationNonDiscrete, &varDecls /*BUFC*/, &tmp)
    ;separator="\n")   
  <<
  <%&tmp%>
  /* for continuous time variables */
  int functionAliasEquations()
  {
    state mem_state;
    <%varDecls%>
  
    mem_state = get_memory_state();
    <%removedPart%>
    restore_memory_state(mem_state);
  
    return 0;
  }
  >>
end functionAliasEquation;

template functionDAE( list<SimEqSystem> allEquationsPlusWhen, 
                list<SimWhenClause> whenClauses,
                list<HelpVarInfo> helpVarInfo)
  "Generates function in simulation file."
::=
  let &varDecls = buffer "" /*BUFD*/
  let jens = System.tmpTickReset(0)
  let &tmp = buffer ""
  let eqs = (allEquationsPlusWhen |> eq =>
      equation_(eq, contextSimulationDiscrete, &varDecls /*BUFD*/, &tmp)
    ;separator="\n")
    
  let reinit = (whenClauses |> when hasindex i0 =>



      genreinits(when, &varDecls,i0)
    ;separator="\n")
  <<
  <%&tmp%>
  int functionDAE(int *needToIterate)
  {
    state mem_state;
    <%varDecls%>
    *needToIterate = 0;
    inUpdate=initial()?0:1;
  
    mem_state = get_memory_state();
    <%eqs%>
    <%reinit%>
    restore_memory_state(mem_state);
  
    inUpdate=0;
  
    return 0;
  }
  >>
end functionDAE;

template functionOnlyZeroCrossing(list<ZeroCrossing> zeroCrossings)
  "Generates function in simulation file."
::=
  let &varDecls = buffer "" /*BUFD*/
  let zeroCrossingsCode = zeroCrossingsTpl2(zeroCrossings, &varDecls /*BUFD*/)
  <<
  int function_onlyZeroCrossings(double *gout,double *t)
  {
    state mem_state;
    <%varDecls%>
  
    mem_state = get_memory_state();
    <%zeroCrossingsCode%>
    restore_memory_state(mem_state);
  
    return 0;
  }
  >>
end functionOnlyZeroCrossing;

template functionCheckForDiscreteChanges(list<ComponentRef> discreteModelVars)
  "Generates function in simulation file."
::=

  let changediscreteVars = (discreteModelVars |> var => match var case CREF_QUAL(__) case CREF_IDENT(__) then
       'if (<%cref(var)%> != $P$PRE<%cref(var)%>) { if (sim_verbose >= LOG_EVENTS) { printf("Discrete Var <%crefStr(var)%> : <%crefToPrintfArg(var)%> to <%crefToPrintfArg(var)%>\n", $P$PRE<%cref(var)%>, <%cref(var)%>); }  needToIterate=1; }'
    ;separator="\n")
  <<
  int checkForDiscreteChanges()
  {
    int needToIterate = 0;
  
    <%changediscreteVars%>
    
    return needToIterate;
  }
  >>
end functionCheckForDiscreteChanges;

template functionJac(list<SimEqSystem> jacEquations, list<SimVar> tmpVars,String columnName, String matrixName)
 "Generates function in simulation file."
::=
  let &varDecls = buffer "" /*BUFD*/
  let &tmp = buffer ""
  let eqns_ = (jacEquations |> eq =>
      equation_(eq, contextSimulationNonDiscrete, &varDecls /*BUFD*/, &tmp)
      ;separator="\n")
  let outvars_ = (tmpVars |> var => 
      genoutVars(var)
      ;separator="\n")
  <<
  <%&tmp%>
  int functionJac<%matrixName%>_0(double *seed, double *out_col)
  {
    state mem_state;
    <%varDecls%>
    mem_state = get_memory_state();
    <%eqns_%>
    
    // write column
    <%outvars_%>
    int i;
    for(i=0;i<<%columnName%>;i++){
        if (sim_verbose == LOG_JAC || sim_verbose == LOG_ENDJAC){
          printf("col: col[%d] = %f \n",i,out_col[i]);
        }
    }
    
    restore_memory_state(mem_state);
    
    return 0;
  }
  >>
end functionJac;

template genoutVars(SimVar var)
 "Generates out variable "
 ::=
match var
  case (SIMVAR(name=name,index=index))then
    match index
      case -1 then
      <<>>
      case _ then
      <<
        out_col[<%index%>] = <%cref(name)%>;
      >>
   end match
end match
end genoutVars;

template generateMatrix(list<JacobianColumn> jacobianMatrix, list<SimVar> seedVars,String matrixname)
 "Generates Matrixes for Linear Model."
::=
match seedVars
case {} then
<<
 int functionJac<%matrixname%>(double* jac){
    return 0;
 }
>>
case _ then
  let jacMats = (jacobianMatrix |> (eqs,vars,name) =>
    functionJac(eqs,vars,name,matrixname)
    ;separator="\n")
  let indexColumn = (jacobianMatrix |> (eqs,vars,name) =>
    name
    ;separator="\n")    
  let writeJac_ = (seedVars |> var hasindex i0 => match var case(SIMVAR(name=name))then <<#define <%cref(name)%> seed[<%i0%>]>>
    ;separator="\n") 
  let index_ = listLength(seedVars)
 <<
 #define _OMC_SEED_HACK double *seed
 #define _OMC_SEED_HACK_2 seed
 <%writeJac_%>
 <%jacMats%>
 int functionJac<%matrixname%>(double* jac){
    double seed[<%index_%>] = {0};
    double localtmp[<%indexColumn%>] = {0};
    int i,j,l,k;
    for(i=0,k=0;  i < <%index_%>;i++){
      seed[i] = 1;
      
      if (sim_verbose == LOG_JAC || sim_verbose == LOG_ENDJAC){
        printf("Caluculate one row:\n");
        for(l=0;  l < <%index_%>;l++){
          printf("seed: seed[%d]= %f\n",l,seed[l]);
        }
      }

      functionJac<%matrixname%>_0(seed,localtmp);
      seed[i] = 0;
      for(j=0; j < <%indexColumn%>;j++)
        jac[k++] = localtmp[j];
    }
  return 0;
 }
 >>
end generateMatrix;

template generateLinearMatrixes(list<JacobianMatrix> JacobianMatrixes)
 "Generates Matrixes for Linear Model."
::=
  let jacMats = (JacobianMatrixes |> (mat, vars, name, _, _, _) =>
    generateMatrix(mat,vars,name)
    ;separator="\n\n")
 <<
 <%jacMats%>
 >>
end generateLinearMatrixes;

template functionlinearmodel(ModelInfo modelInfo)
 "Generates function in simulation file."
::= 
match modelInfo
case MODELINFO(varInfo=VARINFO(__), vars=SIMVARS(__)) then
  let matrixA = genMatrix("A",varInfo.numStateVars,varInfo.numStateVars)
  let matrixB = genMatrix("B",varInfo.numStateVars,varInfo.numInVars)
  let matrixC = genMatrix("C",varInfo.numOutVars,varInfo.numStateVars)
  let matrixD = genMatrix("D",varInfo.numOutVars,varInfo.numInVars)
  let vectorX = genVector("x", varInfo.numStateVars, 0)
  let vectorU = genVector("u", varInfo.numInVars, 1)
  let vectorY = genVector("y", varInfo.numOutVars, 2)
  //string def_proctedpart("\n  Real x[<%varInfo.numStateVars%>](start=x0);\n  Real u[<%varInfo.numInVars%>](start=u0); \n  output Real y[<%varInfo.numOutVars%>]; \n");
  <<
  const char *linear_model_frame =
    "model linear_<%dotPath(name)%>\n  parameter Integer n = <%varInfo.numStateVars%>; // states \n  parameter Integer k = <%varInfo.numInVars%>; // top-level inputs \n  parameter Integer l = <%varInfo.numOutVars%>; // top-level outputs \n"
    "  parameter Real x0[<%varInfo.numStateVars%>] = {%s};\n"
    "  parameter Real u0[<%varInfo.numInVars%>] = {%s};\n"
    <%matrixA%>
    <%matrixB%>
    <%matrixC%>
    <%matrixD%>
    <%vectorX%>
    <%vectorU%>
    <%vectorY%>
    "\n  <%getVarName(vars.stateVars, "x", varInfo.numStateVars )%>  <% getVarName(vars.inputVars, "u", varInfo.numInVars) %>  <%getVarName(vars.outputVars, "y", varInfo.numOutVars) %>\n"
    "equation\n  der(x) = A * x + B * u;\n  y = C * x + D * u;\nend linear_<%dotPath(name)%>;\n"
  ;
  >>
end functionlinearmodel;

template globalDataFixedInt(Boolean isFixed)
 "Generates integer for use in arrays in global data section."
::=
  match isFixed
  case true  then "1"
  case false then "0"
end globalDataFixedInt;

template globalDataNominalValue(Option<DAE.Exp> nominal)
 "Generates integer for use in arrays in global data section."
::=
  match nominal
  case NONE()  then "0 /* default */"
  case SOME(v) then initVal(v)
end globalDataNominalValue;

template globalDataHasNominalValue(Option<DAE.Exp> nominal)
 "Generates integer for use in arrays in global data section."
::=
  match nominal
  case NONE()  then "0"
  case SOME(v) then "1"
end globalDataHasNominalValue;

template globalDataAttrInt(DAE.Type type)
 "Generates integer for use in arrays in global data section."
::=
  match type
  case T_REAL(__)        then "1"
  case T_STRING(__)      then "2"
  case T_INTEGER(__)     then "4"
  case T_ENUMERATION(__) then "4"
  case T_BOOL(__)        then "8"
end globalDataAttrInt;


template globalDataDiscAttrInt(Boolean isDiscrete)
 "Generates integer for use in arrays in global data section."
::=
  match isDiscrete
  case true  then "16"
  case false then "0"
end globalDataDiscAttrInt;

end CodegenQSS;

// vim: filetype=susan sw=2 sts=2
