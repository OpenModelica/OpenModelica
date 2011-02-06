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

package SimCodeC

import interface SimCodeTV;

template translateModel(SimCode simCode) 
 "Generates C code and Makefile for compiling and running a simulation of a
  Modelica model."
::=
match simCode
case SIMCODE(modelInfo=modelInfo as MODELINFO(__)) then
  let()= textFile(simulationFile(simCode), '<%fileNamePrefix%>.cpp')
  let()= textFile(simulationFunctionsHeaderFile(fileNamePrefix, modelInfo.functions, externalFunctionIncludes, recordDecls), '<%fileNamePrefix%>_functions.h')
  let()= textFile(simulationFunctionsFile(fileNamePrefix, modelInfo.functions, literals), '<%fileNamePrefix%>_functions.cpp')
  let()= textFile(recordsFile(fileNamePrefix, recordDecls), '<%fileNamePrefix%>_records.c')
  let()= textFile(simulationMakefile(simCode), '<%fileNamePrefix%>.makefile')
  if simulationSettingsOpt then //tests the Option<> for SOME()
     let()= textFile(simulationInitFile(simCode), '<%fileNamePrefix%>_init.txt')
     "" //empty result for true case 
  //else "" //the else is automatically empty, too
  //this top-level template always returns an empty result 
  //since generated texts are written to files directly
end translateModel;


template translateFunctions(FunctionCode functionCode)
 "Generates C code and Makefile for compiling and calling Modelica and
  MetaModelica functions." 
::=
match functionCode

case FUNCTIONCODE(__) then
  let filePrefix = name
  let()= textFile(functionsHeaderFile(filePrefix, mainFunction, functions, extraRecordDecls, externalFunctionIncludes), '<%filePrefix%>.h')
  let()= textFile(functionsFile(filePrefix, mainFunction, functions, literals), '<%filePrefix%>.c')
  let()= textFile(recordsFile(filePrefix, extraRecordDecls), '<%filePrefix%>_records.c')
  let _= (if mainFunction then textFile(functionsMakefile(functionCode), '<%filePrefix%>.makefile'))
  "" // Return empty result since result written to files directly
end translateFunctions;


template simulationFile(SimCode simCode)
 "Generates code for main C file for simulation target."
::=
match simCode
case SIMCODE(__) then
  <<
  <%simulationFileHeader(simCode)%>
  
  <%globalData(modelInfo)%>
  
  <%equationInfo(appendLists(appendAllequation(JacobianMatrixes),allEquationsPlusWhen))%>
  
  <%functionGetName(modelInfo)%>
  
  <%functionDivisionError()%>
  
  <%functionSetLocalData()%>
  
  <%functionInitializeDataStruc()%>

  <%functionCallExternalObjectConstructors(extObjInfo)%>
  
  <%functionDeInitializeDataStruc(extObjInfo)%>
  
  <%functionExtraResiduals(allEquations)%>
  
  <%functionDaeOutput(nonStateContEquations, removedEquations,
                     algorithmAndEquationAsserts)%>
  
  <%functionDaeOutput2(nonStateDiscEquations, removedEquations)%>
  
  <%functionInput(modelInfo)%>
  
  <%functionOutput(modelInfo)%>
  
  <%functionDaeRes()%>
  
  <%functionZeroCrossing(zeroCrossings)%>
  
  <%functionHandleZeroCrossing(zeroCrossingsNeedSave)%>
  
  <%functionInitSample(sampleConditions)%>
  
  <%functionSampleEquations(sampleEquations)%>

  <%functionUpdateDependents(allEquations, helpVarInfo)%>
  
  <%functionStoreDelayed(delayedExps)%>
  
  <%functionWhen(whenClauses)%>
  
  <%functionOde(stateContEquations)%>
  
  <%functionInitial(initialEquations)%>
  
  <%functionInitialResidual(residualEquations)%>
  
  <%functionBoundParameters(parameterEquations)%>
  
  <%functionCheckForDiscreteVarChanges(helpVarInfo, discreteModelVars)%>
  
  <%functionODE(odeEquations)%>
  
  <%functionODE_residual()%>
  
  <%functionAlgebraic(algebraicEquations)%>
    
  <%functionAliasEquation(removedEquations)%>
                       
  <%functionDAE(allEquationsPlusWhen, whenClauses, helpVarInfo)%>
    
  <%functionOnlyZeroCrossing(zeroCrossings)%>
  
  <%functionCheckForDiscreteChanges(discreteModelVars2)%>
  
  <%generateLinearMatrixes(JacobianMatrixes)%>
  
  <%functionlinearmodel(modelInfo)%>
  
  <%\n%> 
  >>
  /* adrpo: leave a newline at the end of file to get rid of the warning */
end simulationFile;

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
  
  #include "<%fileNamePrefix%>_functions.h"
  
  >>
end simulationFileHeader;


template globalData(ModelInfo modelInfo)
 "Generates global data in simulation file."
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(__), vars=SIMVARS(__)) then
  <<
  #define NHELP <%varInfo.numHelpVars%>
  #define NG <%varInfo.numZeroCrossings%> // number of zero crossings
  #define NG_SAM <%varInfo.numTimeEvents%> // number of zero crossings that are samples
  #define NX <%varInfo.numStateVars%>
  #define NY <%varInfo.numAlgVars%>
  #define NP <%varInfo.numParams%> // number of parameters
  #define NO <%varInfo.numOutVars%> // number of outputvar on topmodel
  #define NI <%varInfo.numInVars%> // number of inputvar on topmodel
  #define NR <%varInfo.numResiduals%> // number of residuals for initialialization function
  #define NEXT <%varInfo.numExternalObjects%> // number of external objects
  #define NFUNC <%listLength(functions)%> // number of functions used by the simulation
  #define MAXORD 5
  #define NYSTR <%varInfo.numStringAlgVars%> // number of alg. string variables
  #define NPSTR <%varInfo.numStringParamVars%> // number of alg. string variables
  #define NYINT <%varInfo.numIntAlgVars%> // number of alg. int variables
  #define NPINT <%varInfo.numIntParams%> // number of alg. int variables
  #define NYBOOL <%varInfo.numBoolAlgVars%> // number of alg. bool variables
  #define NPBOOL <%varInfo.numBoolParams%> // number of alg. bool variables
  #define NJACVARS <%varInfo.numJacobianVars%> // number of jacobian variables
  
  static DATA* localData = 0;
  #define time localData->timeValue
  #define $P$old$Ptime localData->oldTime
  #define $P$current_step_size globalData->current_stepsize

  extern "C" { // adrpo: this is needed for Visual C++ compilation to work!
    const char *model_name="<%dotPath(name)%>";
    const char *model_dir="<%directory%>";
  }
  
  // we need to access the inline define that we compiled the simulation with
  // from the simulation runtime.
  const char *_omc_force_solver=_OMC_FORCE_SOLVER;
  const int inline_work_states_ndims=_OMC_SOLVER_WORK_STATES_NDIMS;
  
  <%globalDataVarInfoArray("state_names", vars.stateVars)%>
  <%globalDataVarInfoArray("derivative_names", vars.derivativeVars)%>
  <%globalDataVarInfoArray("algvars_names", vars.algVars)%>
  <%globalDataVarInfoArray("param_names", vars.paramVars)%>
  <%globalDataVarInfoArray("int_alg_names", vars.intAlgVars)%>
  <%globalDataVarInfoArray("int_param_names", vars.intParamVars)%>
  <%globalDataVarInfoArray("bool_alg_names", vars.boolAlgVars)%>
  <%globalDataVarInfoArray("bool_param_names", vars.boolParamVars)%>
  <%globalDataVarInfoArray("string_alg_names", vars.stringAlgVars)%>
  <%globalDataVarInfoArray("string_param_names", vars.stringParamVars)%>
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
  
  static char init_fixed[NX+NX+NY+NYINT+NYBOOL+NYSTR+NP+NPINT+NPBOOL+NPSTR] = {
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
    const struct omc_varInfo <%_name%>[1] = {{"","",omc_dummyFileInfo}};
    >>
  case items then
    <<
    const struct omc_varInfo <%_name%>[<%listLength(items)%>] = {
      <%items |> var as SIMVAR(info=info as INFO(__)) => '{"<%crefStr(var.name)%>","<%var.comment%>",{<%infoArgs(info)%>}}'; separator=",\n"%>
    };
    <%items |> var as SIMVAR(info=info as INFO(__)) hasindex i0 => '#define <%cref(var.name)%>__varInfo <%_name%>[<%i0%>]'; separator="\n"%>
    >>
end globalDataVarInfoArray;

template globalDataFunctionInfoArray(String name, list<Function> items)
 "Generates array with variable names in global data section."
::=
  match items
  case {} then
    <<
    struct omc_functionInfo <%name%>[1] = {{"",omc_dummyFileInfo}};
    >>
  case items then
    <<
    struct omc_functionInfo <%name%>[<%listLength(items)%>] = {
      <%items |> fn => '{"<%functionName(fn,true)%>",omc_dummyFileInfo}'; separator=",\n"%>
    };
    >>
end globalDataFunctionInfoArray;

template globalDataVarDefine(SimVar simVar, String arrayName)
 "Generates a define statement for a varable in the global data section."
::=
match arrayName
case "jacobianVars" then
  match simVar
  case SIMVAR(__) then
    <<
    #define <%cref(name)%> localData-><%arrayName%>[<%index%>]
    >> 
  end match
case _ then
  match simVar
  case SIMVAR(arrayCref=SOME(c)) then
    <<
    #define <%cref(c)%> localData-><%arrayName%>[<%index%>]
    #define <%cref(name)%> localData-><%arrayName%>[<%index%>]
    #define $P$old<%cref(name)%> localData-><%arrayName%>_old[<%index%>]
    #define $P$old2<%cref(name)%> localData-><%arrayName%>_old2[<%index%>]
    >>
  case SIMVAR(__) then
    <<
    #define <%cref(name)%> localData-><%arrayName%>[<%index%>]
    #define $P$old<%cref(name)%> localData-><%arrayName%>_old[<%index%>]
    #define $P$old2<%cref(name)%> localData-><%arrayName%>_old2[<%index%>]
    >>
end globalDataVarDefine;


template globalDataFixedInt(Boolean isFixed)
 "Generates integer for use in arrays in global data section."
::=
  match isFixed
  case true  then "1"
  case false then "0"
end globalDataFixedInt;


template globalDataAttrInt(DAE.ExpType type)
 "Generates integer for use in arrays in global data section."
::=
  match type
  case ET_REAL(__)        then "1"
  case ET_STRING(__)      then "2"
  case ET_INT(__)         then "4"
  case ET_ENUMERATION(__) then "4"
  case ET_BOOL(__)        then "8"
end globalDataAttrInt;


template globalDataDiscAttrInt(Boolean isDiscrete)
 "Generates integer for use in arrays in global data section."
::=
  match isDiscrete
  case true  then "16"
  case false then "0"
end globalDataDiscAttrInt;


template functionGetName(ModelInfo modelInfo)
 "Generates function in simulation file."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<
  const char* getName(double* ptr)
  {
    <%vars.stateVars |> SIMVAR(__) =>
      'if (&<%cref(name)%> == ptr) return state_names[<%index%>].name;'
    ;separator="\n"%>
    <%vars.derivativeVars |> SIMVAR(__) =>
      'if (&<%cref(name)%> == ptr) return derivative_names[<%index%>].name;'
    ;separator="\n"%>
    <%vars.algVars |> SIMVAR(__) =>
      'if (&<%cref(name)%> == ptr) return algvars_names[<%index%>].name;'
    ;separator="\n"%>
    <%vars.paramVars |> SIMVAR(__) =>
      'if (&<%cref(name)%> == ptr) return param_names[<%index%>].name;'
    ;separator="\n"%>
    return "";
  }
  
  const char* getName(modelica_integer* ptr)
  {
    <%vars.intAlgVars |> SIMVAR(__) =>
      'if (&<%cref(name)%> == ptr) return int_alg_names[<%index%>].name;'
    ;separator="\n"%>
    <%vars.intParamVars |> SIMVAR(__) =>
      'if (&<%cref(name)%> == ptr) return int_param_names[<%index%>].name;'
    ;separator="\n"%>
    return "";
  }
  
  const char* getName(modelica_boolean* ptr)
  {
    <%vars.boolAlgVars |> SIMVAR(__) =>
      'if (&<%cref(name)%> == ptr) return bool_alg_names[<%index%>].name;'
    ;separator="\n"%>
    <%vars.boolParamVars |> SIMVAR(__) =>
      'if (&<%cref(name)%> == ptr) return bool_param_names[<%index%>].name;'
    ;separator="\n"%>
    return "";
  }
  
  >>
end functionGetName;


template functionDivisionError()
 "Generates function in simulation file."
::=
  <<
  /* Commented out by Frenkel TUD because there is a new implementation of
     division by zero problem. */
  /*
  #define DIVISION(a,b,c) ((b != 0) ? a / b : a / division_error(b,c))
  
  int encounteredDivisionByZero = 0;
  
  double division_error(double b, const char* division_str)
  {
    if(!encounteredDivisionByZero) {
      fprintf(stderr, "ERROR: Division by zero in partial equation: %s.\n",division_str);
      encounteredDivisionByZero = 1;
    }
    return b;
  }
  */
  >>
end functionDivisionError;


template functionSetLocalData()
 "Generates function in simulation file."
::=
  <<
  void setLocalData(DATA* data)
  {
    localData = data;
  }
  >>
end functionSetLocalData;


template functionInitializeDataStruc()
 "Generates function in simulation file."
::=
  <<
  DATA* initializeDataStruc(DATA_FLAGS flags)
  {  
    DATA* returnData = (DATA*)malloc(sizeof(DATA));
  
    if(!returnData) //error check
      return 0;
  
    memset(returnData,0,sizeof(DATA));
    returnData->nStates = NX;
    returnData->nAlgebraic = NY;
    returnData->nParameters = NP;
    returnData->nInputVars = NI;
    returnData->nOutputVars = NO;
    returnData->nFunctions = NFUNC;
    returnData->nProfileBlocks = n_omc_equationInfo_reverse_prof_index;
    returnData->nZeroCrossing = NG;
    returnData->nRawSamples = NG_SAM;
    returnData->nInitialResiduals = NR;
    returnData->nHelpVars = NHELP;
    returnData->stringVariables.nParameters = NPSTR;
    returnData->stringVariables.nAlgebraic = NYSTR;
    returnData->intVariables.nParameters = NPINT;
    returnData->intVariables.nAlgebraic = NYINT;
    returnData->boolVariables.nParameters = NPBOOL;
    returnData->boolVariables.nAlgebraic = NYBOOL;
    returnData->nJacobianvars = NJACVARS;
  
    if(flags & STATES && returnData->nStates) {
      returnData->states = (double*) malloc(sizeof(double)*returnData->nStates);
      returnData->states_old = (double*) malloc(sizeof(double)*returnData->nStates);
      returnData->states_old2 = (double*) malloc(sizeof(double)*returnData->nStates);
      assert(returnData->states&&returnData->states_old&&returnData->states_old2);
      memset(returnData->states,0,sizeof(double)*returnData->nStates);
      memset(returnData->states_old,0,sizeof(double)*returnData->nStates);
      memset(returnData->states_old2,0,sizeof(double)*returnData->nStates);
    } else {
      returnData->states = 0;
      returnData->states_old = 0;
      returnData->states_old2 = 0;
    }
  
    if(flags & STATESDERIVATIVES && returnData->nStates) {
      returnData->statesDerivatives = (double*) malloc(sizeof(double)*returnData->nStates);
      returnData->statesDerivatives_old = (double*) malloc(sizeof(double)*returnData->nStates);
      returnData->statesDerivatives_old2 = (double*) malloc(sizeof(double)*returnData->nStates);
      assert(returnData->statesDerivatives&&returnData->statesDerivatives_old&&returnData->statesDerivatives_old2);
      memset(returnData->statesDerivatives,0,sizeof(double)*returnData->nStates);
      memset(returnData->statesDerivatives_old,0,sizeof(double)*returnData->nStates);
      memset(returnData->statesDerivatives_old2,0,sizeof(double)*returnData->nStates);
    } else {
      returnData->statesDerivatives = 0;
      returnData->statesDerivatives_old = 0;
      returnData->statesDerivatives_old2 = 0;
    }
  
    if(flags & HELPVARS && returnData->nHelpVars) {
      returnData->helpVars = (double*) malloc(sizeof(double)*returnData->nHelpVars);
      assert(returnData->helpVars);
      memset(returnData->helpVars,0,sizeof(double)*returnData->nHelpVars);
    } else {
      returnData->helpVars = 0;
    }
  
    if(flags & ALGEBRAICS && returnData->nAlgebraic) {
      returnData->algebraics = (double*) malloc(sizeof(double)*returnData->nAlgebraic);
      returnData->algebraics_old = (double*) malloc(sizeof(double)*returnData->nAlgebraic);
      returnData->algebraics_old2 = (double*) malloc(sizeof(double)*returnData->nAlgebraic);
      assert(returnData->algebraics&&returnData->algebraics_old&&returnData->algebraics_old2);
      memset(returnData->algebraics,0,sizeof(double)*returnData->nAlgebraic);
      memset(returnData->algebraics_old,0,sizeof(double)*returnData->nAlgebraic);
      memset(returnData->algebraics_old2,0,sizeof(double)*returnData->nAlgebraic);
    } else {
      returnData->algebraics = 0;
      returnData->algebraics_old = 0;
      returnData->algebraics_old2 = 0;
    }
  
    if (flags & ALGEBRAICS && returnData->stringVariables.nAlgebraic) {
      returnData->stringVariables.algebraics = (const char**)malloc(sizeof(char*)*returnData->stringVariables.nAlgebraic);
      assert(returnData->stringVariables.algebraics);
      memset(returnData->stringVariables.algebraics,0,sizeof(char*)*returnData->stringVariables.nAlgebraic);
    } else {
      returnData->stringVariables.algebraics=0;
    }
    
    if (flags & ALGEBRAICS && returnData->intVariables.nAlgebraic) {
      returnData->intVariables.algebraics = (modelica_integer*)malloc(sizeof(modelica_integer)*returnData->intVariables.nAlgebraic);
      returnData->intVariables.algebraics_old = (modelica_integer*)malloc(sizeof(modelica_integer)*returnData->intVariables.nAlgebraic);
      returnData->intVariables.algebraics_old2 = (modelica_integer*)malloc(sizeof(modelica_integer)*returnData->intVariables.nAlgebraic);
      assert(returnData->intVariables.algebraics&&returnData->intVariables.algebraics_old&&returnData->intVariables.algebraics_old2);
      memset(returnData->intVariables.algebraics,0,sizeof(modelica_integer)*returnData->intVariables.nAlgebraic);
      memset(returnData->intVariables.algebraics_old,0,sizeof(modelica_integer)*returnData->intVariables.nAlgebraic);
      memset(returnData->intVariables.algebraics_old2,0,sizeof(modelica_integer)*returnData->intVariables.nAlgebraic);
    } else {
      returnData->intVariables.algebraics=0;
      returnData->intVariables.algebraics_old = 0;
      returnData->intVariables.algebraics_old2 = 0;
    }

    if (flags & ALGEBRAICS && returnData->boolVariables.nAlgebraic) {
      returnData->boolVariables.algebraics = (modelica_boolean*)malloc(sizeof(modelica_boolean)*returnData->boolVariables.nAlgebraic);
      returnData->boolVariables.algebraics_old = (signed char*)malloc(sizeof(modelica_boolean)*returnData->boolVariables.nAlgebraic);
      returnData->boolVariables.algebraics_old2 = (signed char*)malloc(sizeof(modelica_boolean)*returnData->boolVariables.nAlgebraic);
      assert(returnData->boolVariables.algebraics&&returnData->boolVariables.algebraics_old&&returnData->boolVariables.algebraics_old2);
      memset(returnData->boolVariables.algebraics,0,sizeof(modelica_boolean)*returnData->boolVariables.nAlgebraic);
      memset(returnData->boolVariables.algebraics_old,0,sizeof(modelica_boolean)*returnData->boolVariables.nAlgebraic);
      memset(returnData->boolVariables.algebraics_old2,0,sizeof(modelica_boolean)*returnData->boolVariables.nAlgebraic);
    } else {
      returnData->boolVariables.algebraics=0;
      returnData->boolVariables.algebraics_old = 0;
      returnData->boolVariables.algebraics_old2 = 0;
    }
    
    if(flags & PARAMETERS && returnData->nParameters) {
      returnData->parameters = (double*) malloc(sizeof(double)*returnData->nParameters);
      assert(returnData->parameters);
      memset(returnData->parameters,0,sizeof(double)*returnData->nParameters);
    } else {
      returnData->parameters = 0;
    }
  
    if (flags & PARAMETERS && returnData->stringVariables.nParameters) {
      returnData->stringVariables.parameters = (const char**)malloc(sizeof(char*)*returnData->stringVariables.nParameters);
        assert(returnData->stringVariables.parameters);
        memset(returnData->stringVariables.parameters,0,sizeof(char*)*returnData->stringVariables.nParameters);
    } else {
        returnData->stringVariables.parameters=0;
    }
    
    if (flags & PARAMETERS && returnData->intVariables.nParameters) {
      returnData->intVariables.parameters = (modelica_integer*)malloc(sizeof(modelica_integer)*returnData->intVariables.nParameters);
        assert(returnData->intVariables.parameters);
        memset(returnData->intVariables.parameters,0,sizeof(modelica_integer)*returnData->intVariables.nParameters);
    } else {
        returnData->intVariables.parameters=0;
    }
    
    if (flags & PARAMETERS && returnData->boolVariables.nParameters) {
      returnData->boolVariables.parameters = (modelica_boolean*)malloc(sizeof(modelica_boolean)*returnData->boolVariables.nParameters);
        assert(returnData->boolVariables.parameters);
        memset(returnData->boolVariables.parameters,0,sizeof(modelica_boolean)*returnData->boolVariables.nParameters);
    } else {
        returnData->boolVariables.parameters=0;
    }
    
    if(flags & OUTPUTVARS && returnData->nOutputVars) {
      returnData->outputVars = (double*) malloc(sizeof(double)*returnData->nOutputVars);
      assert(returnData->outputVars);
      memset(returnData->outputVars,0,sizeof(double)*returnData->nOutputVars);
    } else {
      returnData->outputVars = 0;
    }
  
    if(flags & INPUTVARS && returnData->nInputVars) {
      returnData->inputVars = (double*) malloc(sizeof(double)*returnData->nInputVars);
      assert(returnData->inputVars);
      memset(returnData->inputVars,0,sizeof(double)*returnData->nInputVars);
    } else {
      returnData->inputVars = 0;
    }
  
   if(flags & JACOBIANVARS && returnData->nJacobianvars) {
      returnData->jacobianVars = (double*) malloc(sizeof(double)*returnData->nJacobianvars);
      assert(returnData->jacobianVars);
      memset(returnData->jacobianVars,0,sizeof(double)*returnData->nJacobianvars);
    } else {
      returnData->jacobianVars = 0;
    }
  
    if(flags & INITIALRESIDUALS && returnData->nInitialResiduals) {
      returnData->initialResiduals = (double*) malloc(sizeof(double)*returnData->nInitialResiduals);
      assert(returnData->initialResiduals);
      memset(returnData->initialResiduals,0,sizeof(double)*returnData->nInitialResiduals);
    } else {
      returnData->initialResiduals = 0;
    }
  
    if(flags & INITFIXED) {
      returnData->initFixed = init_fixed;
    } else {
      returnData->initFixed = 0;
    }
  
    /*   names   */
    if(flags & MODELNAME) {
      returnData->modelName = model_name;
    } else {
      returnData->modelName = 0;
    }
    
    if(flags & STATESNAMES) {
      returnData->statesNames = state_names;
    } else {
      returnData->statesNames = 0;
    }
  
    if(flags & STATESDERIVATIVESNAMES) {
      returnData->stateDerivativesNames = derivative_names;
    } else {
      returnData->stateDerivativesNames = 0;
    }
  
    if(flags & ALGEBRAICSNAMES) {
      returnData->algebraicsNames = algvars_names;
    } else {
      returnData->algebraicsNames = 0;
    }
    
    if(flags & ALGEBRAICSNAMES) {
      returnData->int_alg_names = int_alg_names;
    } else {
      returnData->int_alg_names = 0;
    }

    if(flags & ALGEBRAICSNAMES) {
      returnData->bool_alg_names = bool_alg_names;
    } else {
      returnData->bool_alg_names = 0;
    }
  
    if(flags & PARAMETERSNAMES) {
      returnData->parametersNames = param_names;
    } else {
      returnData->parametersNames = 0;
    }
    
    if(flags & PARAMETERSNAMES) {
      returnData->int_param_names = int_param_names;
    } else {
      returnData->int_param_names = 0;
    }

    if(flags & PARAMETERSNAMES) {
      returnData->bool_param_names = bool_param_names;
    } else {
      returnData->bool_param_names = 0;
    }
    
    if(flags & JACOBIANNAMES) {
      returnData->jacobian_names = jacobian_names;
    } else {
      returnData->jacobian_names = 0;
    }
    
    if(flags & FUNCTIONNAMES) {
      returnData->functionNames = function_names;
    } else {
      returnData->functionNames = 0;
    }

    if(flags & EQUATIONINFO) {
      returnData->equationInfo = equation_info;
      returnData->equationInfo_reverse_prof_index = omc_equationInfo_reverse_prof_index;
    } else {
      returnData->equationInfo = 0;
    }

    if(flags & RAWSAMPLES && returnData->nRawSamples) {
      returnData->rawSampleExps = (sample_raw_time*) malloc(sizeof(sample_raw_time)*returnData->nRawSamples);
      assert(returnData->rawSampleExps);
      memset(returnData->rawSampleExps,0,sizeof(sample_raw_time)*returnData->nRawSamples);
    } else {
      returnData->rawSampleExps = 0;
    }

    if (flags & EXTERNALVARS) {
      returnData->extObjs = (void**)malloc(sizeof(void*)*NEXT);
      if (!returnData->extObjs) {
        printf("error allocating external objects\n");
        exit(-2);
      }
      memset(returnData->extObjs,0,sizeof(void*)*NEXT);
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
  let &varDecls = buffer "" /*BUFD*/
  let &preExp = buffer "" /*BUFD*/
  let ctorCalls = (constructors |> (var, fnName, args) =>
      let argsStr = (args |> arg =>
          daeExp(arg, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/)
        ;separator=", ")
      '<%cref(var)%> = <%fnName%>(<%argsStr%>);'
    ;separator="\n")
  <<
  /* Has to be performed after _init.txt file has been read */
  void callExternalObjectConstructors(DATA* localData) {
    <%varDecls%>
    <%preExp%>
    <%ctorCalls%>
    <%aliases |> (var1, var2) => '<%cref(var1)%> = <%cref(var2)%>;' ;separator="\n"%>
  }

  >>
end functionCallExternalObjectConstructors;


template functionDeInitializeDataStruc(ExtObjInfo extObjInfo)
 "Generates function in simulation file."
::=
match extObjInfo
case EXTOBJINFO(__) then
  <<
  void deInitializeDataStruc(DATA* data, DATA_FLAGS flags)
  {
    if(!data)
      return;
  
    if(flags & STATES && data->states) {
      free(data->states);
      data->states = 0;
    }
  
    if(flags & STATES && data->states_old) {
      free(data->states_old);
      data->states_old = 0;
    }

    if(flags & STATES && data->states_old2) {
      free(data->states_old2);
      data->states_old2 = 0;
    }

    if(flags & STATESDERIVATIVES && data->statesDerivatives) {
      free(data->statesDerivatives);
      data->statesDerivatives = 0;
    }
  
    if(flags & STATESDERIVATIVES && data->statesDerivatives_old) {
      free(data->statesDerivatives_old);
      data->statesDerivatives_old = 0;
    }
  
    if(flags & STATESDERIVATIVES && data->statesDerivatives_old2) {
      free(data->statesDerivatives_old2);
      data->statesDerivatives_old2 = 0;
    }
  
    if(flags & ALGEBRAICS && data->algebraics) {
      free(data->algebraics);
      data->algebraics = 0;
    }
  
    if(flags & ALGEBRAICS && data->algebraics_old) {
      free(data->algebraics_old);
      data->algebraics_old = 0;
    }
  
    if(flags & ALGEBRAICS && data->algebraics_old2) {
      free(data->algebraics_old2);
      data->algebraics_old2 = 0;
    }
  
    if(flags & PARAMETERS && data->parameters) {
      free(data->parameters);
      data->parameters = 0;
    }
  
    if(flags & INPUTVARS && data->inputVars) {
      free(data->inputVars);
      data->inputVars = 0;
    }
  
    if(flags & OUTPUTVARS && data->outputVars) {
      free(data->outputVars);
      data->outputVars = 0;
    }
    
    if(flags & JACOBIANVARS && data->jacobianVars) {
      free(data->jacobianVars);
      data->jacobianVars = 0;
    }
    
    if(flags & INITIALRESIDUALS && data->initialResiduals){
      free(data->initialResiduals);
      data->initialResiduals = 0;
    }
    if (flags & EXTERNALVARS && data->extObjs) {
      <%destructors |> (fnName, var) => '<%fnName%>(<%cref(var)%>);' ;separator="\n"%>
      free(data->extObjs);
      data->extObjs = 0;
    }
    if(flags & RAWSAMPLES && data->rawSampleExps) {
      free(data->rawSampleExps);
      data->rawSampleExps = 0;
    }
    /* adrpo: 2010-12-17 THIS IS WRONG as WE DO NOT ALLOCATE THIS in function initializeDataStruc!         
    if(flags & RAWSAMPLES && data->sampleTimes) {
      free(data->sampleTimes);
      data->sampleTimes = 0;
    }
    */
  }
  >>
end functionDeInitializeDataStruc;

template functionDaeOutput(list<SimEqSystem> nonStateContEquations,
                  list<SimEqSystem> removedEquations,
                  list<DAE.Statement> algorithmAndEquationAsserts)
 "Generates function in simulation file."
::=
  let &varDecls = buffer "" /*BUFD*/
  let nonStateContPart = (nonStateContEquations |> eq =>
      equation_(eq, contextSimulationNonDiscrete, &varDecls /*BUFD*/)
    ;separator="\n")
  let algAndEqAssertsPart = (algorithmAndEquationAsserts |> stmt =>
      algStatement(stmt, contextSimulationNonDiscrete, &varDecls /*BUFD*/)
    ;separator="\n")
  let removedPart = (removedEquations |> eq =>
      equation_(eq, contextSimulationNonDiscrete, &varDecls /*BUFD*/)
    ;separator="\n")
  <<
  /* for continuous time variables */
  int functionDAE_output()
  {
    state mem_state;
    <%varDecls%>
  
    mem_state = get_memory_state();
    <%nonStateContPart%>
    <%algAndEqAssertsPart%>
    <%removedPart%>
    restore_memory_state(mem_state);
  
    return 0;
  }
  >>
end functionDaeOutput;


template functionDaeOutput2(list<SimEqSystem> nonStateDiscEquations,
                   list<SimEqSystem> removedEquations)
 "Generates function in simulation file."
::=
  let &varDecls = buffer "" /*BUFD*/
  let nonSateDiscPart = (nonStateDiscEquations |> eq =>
      equation_(eq, contextSimulationDiscrete, &varDecls /*BUFD*/)
    ;separator="\n")
  let removedPart = (removedEquations |> eq =>
      equation_(eq, contextSimulationDiscrete, &varDecls /*BUFD*/)
    ;separator="\n")
  <<
  /* for discrete time variables */
  int functionDAE_output2()
  {
    state mem_state;
    <%varDecls%>
  
    mem_state = get_memory_state();
    <%nonSateDiscPart%>
    <%removedPart%>
    restore_memory_state(mem_state);
  
    return 0;
  }
  >>
end functionDaeOutput2;


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


template functionDaeRes()
  "Generates function in simulation file."
::=
  <<
  int functionDAE_res(double *t, double *x, double *xd, double *delta,
                      fortran_integer *ires, double *rpar, fortran_integer *ipar)
  {
    int i;
    double temp_xd[NX];
  #if NY>0    
    double temp_alg[NY];
  #endif
    double* statesBackup;
    double* statesDerivativesBackup;
    double* algebraicsBackup;
    double timeBackup;
  
    statesBackup = localData->states;
    statesDerivativesBackup = localData->statesDerivatives;
  #if NY>0 
      algebraicsBackup = localData->algebraics;
  #endif
    timeBackup = localData->timeValue;
    localData->states = x;
    
    localData->statesDerivatives = temp_xd;
  #if NY>0   
    localData->algebraics = temp_alg;
  #endif
    localData->timeValue = *t;
  
    memcpy(localData->statesDerivatives, statesDerivativesBackup, localData->nStates*sizeof(double));
  #if NY>0     
    memcpy(localData->algebraics, algebraicsBackup, localData->nAlgebraic*sizeof(double));
  #endif
  
    functionODE();
  
    /* get the difference between the temp_xd(=localData->statesDerivatives)
       and xd(=statesDerivativesBackup) */
    for (i=0; i < localData->nStates; i++) {
      delta[i] = localData->statesDerivatives[i] - statesDerivativesBackup[i];
    }
  
    localData->states = statesBackup;
    localData->statesDerivatives = statesDerivativesBackup;
  #if NY>0 
    localData->algebraics = algebraicsBackup;
  #endif
    localData->timeValue = timeBackup;
  
    if (modelErrorCode) {
      if (ires) {
        *ires = -1;
      }
      modelErrorCode =0;
    }
  
    return 0;
  }
  >>
end functionDaeRes;


template functionZeroCrossing(list<ZeroCrossing> zeroCrossings)
  "Generates function in simulation file."
::=
  let &varDecls = buffer "" /*BUFD*/
  let zeroCrossingsCode = zeroCrossingsTpl(zeroCrossings, &varDecls /*BUFD*/)
  <<
  int function_zeroCrossing(fortran_integer *neqm, double *t, double *x, fortran_integer *ng,
                            double *gout, double *rpar, fortran_integer* ipar)
  {
    double timeBackup;
    state mem_state;
  
    mem_state = get_memory_state();
  
    timeBackup = localData->timeValue;
    localData->timeValue = *t;
    <%varDecls%>
  
    functionODE();
    functionDAE_output();
  
    <%zeroCrossingsCode%>
  
    restore_memory_state(mem_state);
    localData->timeValue = timeBackup;
  
    return 0;
  }
  >>
end functionZeroCrossing;


template functionHandleZeroCrossing(list<list<SimVar>> zeroCrossingsNeedSave)
  "Generates function in simulation file."
::=
  <<
  /* This function should only save in cases. The rest is done in
     function_updateDependents. */
  int handleZeroCrossing(long index)
  {
    state mem_state;
  
    mem_state = get_memory_state();
  
    switch(index) {
      <%zeroCrossingsNeedSave |> vars hasindex i0 =>
        <<
        case <%i0%>:
          <%vars |> SIMVAR(__) => 'save(<%cref(name)%>);' ;separator="\n"%>
          break;
        >>
      ;separator="\n"%>
      default:
        break;
    }
  
    restore_memory_state(mem_state);
  
    return 0;
  }
  >>
end functionHandleZeroCrossing;

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
  let eqs = (sampleEqns |> eq =>
      equation_(eq, contextSimulationDiscrete, &varDecls /*BUFD*/)
    ;separator="\n")
  <<
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
 
template functionUpdateDependents(list<SimEqSystem> allEquations,
                                  list<HelpVarInfo> helpVarInfo)
 "Generates function in simulation file."
::=
  let &varDecls = buffer "" /*BUFD*/
  let eqs = (allEquations |> eq =>
      equation_(eq, contextSimulationDiscrete, &varDecls /*BUFD*/)
    ;separator="\n")
  let hvars = (helpVarInfo |> (hindex, exp, _) =>
      let &preExp = buffer "" /*BUFD*/
      let expPart = daeExp(exp, contextSimulationDiscrete, &preExp /*BUFC*/,
                         &varDecls /*BUFD*/)
      '<%preExp%>localData->helpVars[<%hindex%>] = <%expPart%>;'
    ;separator="\n")
  <<
  int function_updateDependents()
  {
    state mem_state;
    <%varDecls%>
  
    inUpdate=initial()?0:1;
  
    mem_state = get_memory_state();
    <%eqs%>
    <%hvars%>
    restore_memory_state(mem_state);
  
    inUpdate=0;
  
    return 0;
  }
  >>
end functionUpdateDependents;

template functionInitial(list<SimEqSystem> initialEquations)
 "Generates function in simulation file."
::=
  let &varDecls = buffer "" /*BUFD*/
  let eqPart = (initialEquations |> eq as SES_SIMPLE_ASSIGN(__) =>
      equation_(eq, contextOther, &varDecls /*BUFD*/)
    ;separator="\n")
  <<
  int initial_function()
  {
    <%varDecls%>
  
    <%eqPart%>
  
    <%initialEquations |> SES_SIMPLE_ASSIGN(__) =>
      'if (sim_verbose) { printf("Setting variable start value: %s(start=%f)\n", "<%cref(cref)%>", <%cref(cref)%>); }'
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
        '<%preExp%>localData->initialResiduals[i++] = <%expPart%>;'
    ;separator="\n")
  <<
  int initial_residual()
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
  (allEquations |> eq as SES_NONLINEAR(__) =>
     let &varDecls = buffer "" /*BUFD*/
     let algs = (eq.eqs |> eq2 as SES_ALGORITHM(__) =>
         equation_(eq2, contextSimulationDiscrete, &varDecls /*BUFD*/)
       ;separator="\n")      
     let prebody = (eq.eqs |> eq2 as SES_SIMPLE_ASSIGN(__) =>
         equation_(eq2, contextOther, &varDecls /*BUFD*/)
       ;separator="\n")   
     let body = (eq.eqs |> eq2 as SES_RESIDUAL(__) hasindex i0 =>
         let &preExp = buffer "" /*BUFD*/
         let expPart = daeExp(eq2.exp, contextSimulationDiscrete,
                            &preExp /*BUFC*/, &varDecls /*BUFD*/)
         '<%preExp%>res[<%i0%>] = <%expPart%>;'
       ;separator="\n")
     <<
     void residualFunc<%index%>(int *n, double* xloc, double* res, int* iflag)
     {
       state mem_state;
       <%varDecls%>
       SIM_PROF_TICK_EQ(SIM_PROF_EQ_<%index%>);
       mem_state = get_memory_state();
       <%algs%>
       <%prebody%>
       <%body%>
       restore_memory_state(mem_state);
       SIM_PROF_ACC_EQ(SIM_PROF_EQ_<%index%>);
     }
     >>
   ;separator="\n\n")
end functionExtraResiduals;


template functionBoundParameters(list<SimEqSystem> parameterEquations)
 "Generates function in simulation file."
::=
  let &varDecls = buffer "" /*BUFD*/
  let body = (parameterEquations |> eq as SES_SIMPLE_ASSIGN(__) =>
      equation_(eq, contextOther, &varDecls /*BUFD*/)
    ;separator="\n")
  let divbody = (parameterEquations |> eq as SES_ALGORITHM(__) =>
      equation_(eq, contextOther, &varDecls /*BUFD*/)
    ;separator="\n")    
  <<
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

//TODO: Is the -1 windex check really correct? It seems to work.
template functionCheckForDiscreteVarChanges(list<HelpVarInfo> helpVarInfo,
                                            list<ComponentRef> discreteModelVars)
 "Generates function in simulation file."
::=
  <<
  int checkForDiscreteVarChanges()
  {
    int needToIterate = 0;
  
    <%helpVarInfo |> (hindex, exp, windex) =>
      match windex //if windex is not -1 then
      case -1 then ""
      else
        'if (edge(localData->helpVars[<%hindex%>])) AddEvent(<%windex%> + localData->nZeroCrossing);'
    ;separator="\n"%>
  
    <%discreteModelVars |> var =>
      'if (change(<%cref(var)%>)) { needToIterate=1; }'
    ;separator="\n"%>
    
    for (long i = 0; i < localData->nHelpVars; i++) {
      if (change(localData->helpVars[i])) {
        needToIterate=1;
      }
    }
  
    return needToIterate;
  }
  >>
end functionCheckForDiscreteVarChanges;

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
      storeDelayedExpression(<%id%>, <%eRes%>);
      >>
    ))
  <<
  extern int const numDelayExpressionIndex = <%match delayed case DELAYED_EXPRESSIONS(__) then maxDelayedIndex%>;
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


template functionWhen(list<SimWhenClause> whenClauses)
  "Generates function in simulation file."
::=
  let &varDecls = buffer "" /*BUFD*/
  let cases = (whenClauses |> SIM_WHEN_CLAUSE(__) hasindex i0 =>
      <<
      case <%i0%>:
        <%functionWhenCaseEquation(whenEq, &varDecls /*BUFD*/)%>
        <%reinits |> reinit =>
          let body = functionWhenReinitStatement(reinit, &varDecls /*BUFD*/)
          '<%body%>'
        ;separator="\n"%>
        break;<%\n%>
      >>
    )
  <<
  int function_when(int i)
  {
    state mem_state;
    <%varDecls%>
  
    mem_state = get_memory_state();
  
    switch(i) {
      <%cases%>
      default:
        break;
    }
  
    restore_memory_state(mem_state);
  
    return 0;
  }
  >>
end functionWhen;


template functionWhenCaseEquation(Option<WhenEquation> when, Text &varDecls /*BUFP*/)
  "Generates content of case-clause for a when equation in function_when."
::=
match when
case SOME(weq as WHEN_EQ(__)) then

  let &preExp = buffer "" /*BUFD*/
  let expPart = daeExp(weq.right, contextSimulationDiscrete,
                     &preExp /*BUFC*/, &varDecls /*BUFD*/)
  <<
  save(<%cref(weq.left)%>);
  
  <%preExp%>
  <%cref(weq.left)%> = <%expPart%>;
  >>
end functionWhenCaseEquation;


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


template genreinits(SimWhenClause whenClauses, Text &varDecls, Integer int)
" Generates reinit statemeant"
::=

match whenClauses
case SIM_WHEN_CLAUSE(__) then
  let &preExp = buffer "" /*BUFD*/
  let &helpInits = buffer "" /*BUFD*/
  let helpIf = (conditions |> (e, hidx) =>
      let helpInit = daeExp(e, contextSimulationDiscrete, &preExp /*BUFC*/, &varDecls /*BUFD*/)
      let &helpInits += 'localData->helpVars[<%hidx%>] = <%helpInit%>;'
      'edge(localData->helpVars[<%hidx%>])'
    ;separator=" || ")  
  let ifthen = functionWhenReinitStatementThen(reinits, &varDecls /*BUFP*/)                     

if reinits then  
<<

  //For whenclause index: <%int%>
  <%preExp%>
  <%helpInits%>
  if (<%helpIf%>) { 
    <%ifthen%>
  }
>>
end genreinits;


template functionWhenReinitStatementThen(list<WhenOperator> reinits, Text &varDecls /*BUFP*/)
 "Generates re-init statement for when equation."
::=
  let body = (reinits |> reinit =>
    match reinit
    case REINIT(__) then 
      let &preExp = buffer "" /*BUFD*/
      let val = daeExp(value, contextSimulationDiscrete,
                   &preExp /*BUFC*/, &varDecls /*BUFD*/)
     <<
      <%preExp%>
                <%cref(stateVar)%> = <%val%>;
                needToIterate=1;
                >>
    case TERMINATE(__) then 
      let &preExp = buffer "" /*BUFD*/
    let msgVar = daeExp(message, contextSimulationDiscrete, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    <<  
                <%preExp%> 
                MODELICA_TERMINATE(<%msgVar%>);
                >>
  case ASSERT(source=SOURCE(info=info)) then 
    assertCommon(condition, message, contextSimulationDiscrete, &varDecls, info)
  ;separator="\n")
  <<
   <%body%>  
  >>
end functionWhenReinitStatementThen;


template functionWhenReinitStatementElse(list<WhenOperator> reinits, Text &preExp /*BUFP*/,
                            Text &varDecls /*BUFP*/)
 "Generates re-init statement for when equation."
::=
  let body = (reinits |> reinit =>
    match reinit
    case REINIT(__) then 
      let val = daeExp(value, contextSimulationDiscrete,
                   &preExp /*BUFC*/, &varDecls /*BUFD*/)
      '<%cref(stateVar)%> = pre(<%cref(stateVar)%>);';separator="\n"
    )
  <<
   <%body%>  
  >>
end functionWhenReinitStatementElse;

template functionOde(list<SimEqSystem> stateContEquations)
 "Generates function in simulation file."
::=
  let &varDecls = buffer "" /*BUFD*/
  let stateContPart = (stateContEquations |> eq =>
      equation_(eq, contextSimulationNonDiscrete, &varDecls /*BUFD*/)
    ;separator="\n")
  let &varDecls2 = buffer "" /*BUFD*/
  let stateContPartInline = (stateContEquations |> eq =>
      equation_(eq, contextInlineSolver, &varDecls2 /*BUFC*/)
    ;separator="\n")
  <<
  int functionODE()
  {
    state mem_state;
    <%varDecls%>
  
    mem_state = get_memory_state();
    <%stateContPart%>
    restore_memory_state(mem_state);
  
    return 0;
  }

  #if defined(_OMC_ENABLE_INLINE)
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
  #else
  int functionODE_inline()
  {
    return 0;
  }
  #endif
  >>
end functionOde;

template functionODE(list<SimEqSystem> derivativEquations)
 "Generates function in simulation file."
::=
  let &varDecls = buffer "" /*BUFD*/
  let odeEquations = (derivativEquations |> eq =>
      equation_(eq, contextSimulation2NonDiscrete, &varDecls /*BUFC*/)
    ;separator="\n")
  <<
  int functionODE_new()
  {
    state mem_state;
    <%varDecls%>
  
    mem_state = get_memory_state();
    <%odeEquations%>
    restore_memory_state(mem_state);
  
    return 0;
  }
  >>
end functionODE;

template functionAlgebraic(list<SimEqSystem> algebraicEquations)
 "Generates function in simulation file."
::=
  let &varDecls = buffer "" /*BUFD*/
  let algEquations = (algebraicEquations |> eq =>
      equation_(eq, contextSimulation2NonDiscrete, &varDecls /*BUFC*/)
    ;separator="\n")
  <<
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

template functiondiscreteAlgebraics(list<SimEqSystem> discalgebraicEquations)
 "Generates function in simulation file."
::=
  let &varDecls = buffer "" /*BUFD*/
  let discalgEquations = (discalgebraicEquations |> eq =>
      equation_(eq, contextSimulation2NonDiscrete, &varDecls /*BUFC*/)
    ;separator="\n")
  <<
  /* for continuous time variables */
  int functiondiscAlgebraics()
  {
    state mem_state;
    <%varDecls%>
  
    mem_state = get_memory_state();
    <%discalgEquations%>
    restore_memory_state(mem_state);
  
    return 0;
  }
  >>
end functiondiscreteAlgebraics;

template functionAliasEquation(list<SimEqSystem> removedEquations)
 "Generates function in simulation file."
::=
  let &varDecls = buffer "" /*BUFD*/
  let removedPart = (removedEquations |> eq =>
      equation_(eq, contextSimulation2NonDiscrete, &varDecls /*BUFC*/)
    ;separator="\n")   
  <<
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


template functionODE_residual()
  "Generates residual function for dassl in simulation file."
::=
  <<
  int functionODE_residual(double *t, double *x, double *xd, double *delta,
                      fortran_integer *ires, double *rpar, fortran_integer *ipar)
  {
    int i;
    double temp_xd[NX];
    double* statesBackup;
    double* statesDerivativesBackup;
    double timeBackup;
  
    timeBackup = localData->timeValue;
    statesBackup = localData->states;
    statesDerivativesBackup = localData->statesDerivatives;
    
    localData->timeValue = *t;
    localData->states = x;
    localData->statesDerivatives = temp_xd;
    
    memcpy(localData->statesDerivatives, statesDerivativesBackup, localData->nStates*sizeof(double));
  
    functionODE_new();
  
    /* get the difference between the temp_xd(=localData->statesDerivatives)
       and xd(=statesDerivativesBackup) */
    for (i=0; i < localData->nStates; i++) {
      delta[i] = localData->statesDerivatives[i] - statesDerivativesBackup[i];
    }
  
    localData->states = statesBackup;
    localData->statesDerivatives = statesDerivativesBackup;
    localData->timeValue = timeBackup;
  
    if (modelErrorCode) {
      if (ires) {
        *ires = -1;
      }
      modelErrorCode =0;
    }
  
    return 0;
  }
  >>
end functionODE_residual;

template functionDAE( list<SimEqSystem> allEquationsPlusWhen, 
                list<SimWhenClause> whenClauses,
                list<HelpVarInfo> helpVarInfo)
  "Generates function in simulation file."
::=
  let &varDecls = buffer "" /*BUFD*/
  let eqs = (allEquationsPlusWhen |> eq =>
      equation_(eq, contextSimulation2Discrete, &varDecls /*BUFD*/)
    ;separator="\n")
    
  let reinit = (whenClauses |> when hasindex i0 =>
      genreinits(when, &varDecls,i0)
    ;separator="\n")
  <<
  int functionDAE(int &needToIterate)
  {
    state mem_state;
    <%varDecls%>
    needToIterate = 0;
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
  <<
  int checkForDiscreteChanges()
  {
    int needToIterate = 0;
  
    <%discreteModelVars |> var as CREF_IDENT(__) =>
      'if (change(<%cref(var)%>)) { if (sim_verbose) { cout << "Discrete Var <%crefStr(var)%> : " << (<%extType(identType)%>) pre(<%cref(var)%>) << " to " << (<%extType(identType)%>) <%cref(var)%> << endl;}  needToIterate=1; }'
    ;separator="\n"%>
    
    return needToIterate;
  }
  >>
//  if (sim_verbose) { cout << "Discrete Var <%crefStr(var)%> : " << (double) pre(<%cref(var)%>) << " to " << (double) <%cref(var)%> << endl;} 
end functionCheckForDiscreteChanges;

template functionJac(list<SimEqSystem> JacEquations, list<SimVar> JacVars, String MatrixName)
 "Generates function in simulation file."
::=
  let &varDecls = buffer "" /*BUFD*/
  let Equations_ = (JacEquations |> eq =>
      equation_(eq, contextSimulationNonDiscrete, &varDecls /*BUFD*/)
    ;separator="\n")
  let Vars_ = (JacVars |> var => 
      defvars(var)
      ;separator="\n")
  let writeJac_ = (JacVars |> var => 
      writejac(var)
    ;separator="\n")   
  <<
  int functionJac<%MatrixName%>(double *t, double *x, double *xd, double *jac)
  {
    state mem_state;
    
    double* statesBackup;
    double* statesDerivativesBackup;
    double timeBackup;
    
    timeBackup = localData->timeValue;
    statesBackup = localData->states;
    statesDerivativesBackup = localData->statesDerivatives;
    localData->timeValue = *t;
    localData->states = x;
    localData->statesDerivatives = xd;
    
    <%Vars_%>
    <%varDecls%>
  
    mem_state = get_memory_state();
    <%Equations_%>
    <%writeJac_%>
    restore_memory_state(mem_state);
    
    localData->states = statesBackup;
    localData->statesDerivatives = statesDerivativesBackup;
    localData->timeValue = timeBackup;
    
    return 0;
  }
  
  >>
end functionJac;

template defvars(SimVar item)
"Declare variables"
::=
match item
case SIMVAR(__) then 
  <<
  <%cref(name)%> = 0;
  >>
end defvars;

template writejac(SimVar item)
"Declare variables"
::=
match item
case SIMVAR(name=name, index=index) then
  match index
  case -1 then
  <<>>
  case _ then
  <<
  jac[<%index%>] = <%cref(name)%>;
  >>
end writejac;

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
  int linear_model_frame(string &out, string A, string B, string C, string D, string x_startvalues, string u_startvalues)
  {
    string def_head("model linear_<%dotPath(name)%>\n  parameter Integer n = <%varInfo.numStateVars%>; // states \n  parameter Integer k = <%varInfo.numInVars%>; // top-level inputs \n  parameter Integer l = <%varInfo.numOutVars%>; // top-level outputs \n");
        
    string def_init_states("  parameter Real x0[<%varInfo.numStateVars%>] = {");
    string def_init_states_end("};\n");

    string def_init_inputs("  parameter Real u0[<%varInfo.numInVars%>] = {");
    string def_init_inputs_end("};\n");
  
    <%vectorX%>
    <%vectorU%>
    <%vectorY%>
  
    <%matrixA%>
    <%matrixB%>
    <%matrixC%>
    <%matrixD%>
  
    string def_Variable("\n  <%getVarName(vars.stateVars, "x", varInfo.numStateVars )%>  <% getVarName(vars.inputVars, "u", varInfo.numInVars) %>  <%getVarName(vars.outputVars, "y", varInfo.numOutVars) %>\n");
  
    string def_tail("equation\n  der(x) = A * x + B * u;\n  y = C * x + D * u;\nend linear_<%dotPath(name)%>;\n");
    
    out += def_head.data();
    out += def_init_states.data();
    out += x_startvalues.data();
    out += def_init_states_end.data();
    out += def_init_inputs.data();
    out += u_startvalues.data();
    out += def_init_inputs_end.data();
    out += def_matrixA_start.data();
    out += A.data();
    out += def_matrixA_end.data();
    out += def_matrixB_start.data();
    out += B.data();
    out += def_matrixB_end.data();
    out += def_matrixC_start.data();
    out += C.data();
    out += def_matrixC_end.data();
    out += def_matrixD_start.data();
    out += D.data();
    out += def_matrixD_end.data();
    out += def_vectorx.data();
    out += def_vectoru.data();
    out += def_vectory.data();
    out += def_Variable.data();
    out += def_tail.data();
    return 0;
  }

  >>
end functionlinearmodel;

template getVarName(list<SimVar> simVars, String arrayName, Integer arraySize)
 "Generates name for a varables."
::=
  match simVars
  case {} then
    <<
    >>
  case (var :: restVars) then
    let rest = getVarName(restVars, arrayName, arraySize)
    let arrindex = decrementInt(arraySize,listLength(restVars))
    match var
    case SIMVAR(__) then 
      <<
      Real <%arrayName%>_<%crefM(name)%> = <%arrayName%>[<%arrindex%>];\n  <%rest%>
      >>
end getVarName;

template genMatrix(String name, Integer row, Integer col)
 "Generates Matrix for linear model"
::=
match row
case 0 then
    <<
    string def_matrix<%name%>_start("  parameter Real <%name%>[<%row%>,<%col%>] = zeros(<%row%>,<%col%>);\n");
    string def_matrix<%name%>_end("");
    >>
case _ then
  match col
  case 0 then
    <<
    string def_matrix<%name%>_start("  parameter Real <%name%>[<%row%>,<%col%>] = zeros(<%row%>,<%col%>);\n");
    string def_matrix<%name%>_end("");
    >>
    case _ then
    <<
    string def_matrix<%name%>_start("  parameter Real <%name%>[<%row%>,<%col%>] = [");
    string def_matrix<%name%>_end("];\n");
    >>
    end match
end match                   
end genMatrix;

template genVector(String name, Integer numIn, Integer flag)
 "Generates variables Vectors for linear model"
::=
match flag
case 0 then 
  match numIn
  case 0 then
      <<
      string def_vector<%name%>("  Real <%name%>[<%numIn%>];\n");
      >>
  case _ then
      <<
      string def_vector<%name%>("  Real <%name%>[<%numIn%>](start=<%name%>0);\n");
      >>
  end match
case 1 then 
  match numIn
  case 0 then
      <<
      string def_vector<%name%>("  input Real <%name%>[<%numIn%>];\n");
      >>
  case _ then
      <<
      string def_vector<%name%>("  input Real <%name%>[<%numIn%>](start= <%name%>0);\n");
      >>
  end match
case 2 then 
  match numIn
  case 0 then
      <<
      string def_vector<%name%>("  output Real <%name%>[<%numIn%>];\n");
      >>
  case _ then
      <<
      string def_vector<%name%>("  output Real <%name%>[<%numIn%>];\n");
      >>
  end match                         
end genVector;

template generateLinearMatrixes(list<JacobianMatrix> JacobianMatrixes)
 "Generates Matrixes for Linear Model."
::=
  let jacMats = (JacobianMatrixes |> (eqs,vars,name) =>
    functionJac(eqs,vars,name)
    ;separator="\n")
 <<
 <%jacMats%>
 >>
end generateLinearMatrixes;

template zeroCrossingsTpl2(list<ZeroCrossing> zeroCrossings, Text &varDecls /*BUFP*/)
 "Generates code for zero crossings."
::=

  (zeroCrossings |> ZERO_CROSSING(__) hasindex i0 =>
    zeroCrossingTpl2(i0, relation_, &varDecls /*BUFD*/)
  ;separator="\n")
end zeroCrossingsTpl2;


template zeroCrossingTpl2(Integer index1, Exp relation, Text &varDecls /*BUFP*/)
 "Generates code for a zero crossing."
::=
  match relation
  case RELATION(__) then
    let &preExp = buffer "" /*BUFD*/
    let e1 = daeExp(exp1, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let op = zeroCrossingOpFunc(operator)
    let e2 = daeExp(exp2, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    <<
    <%preExp%>
    ZEROCROSSING(<%index1%>, <%op%>(<%e1%>, <%e2%>));
    >>
  case CALL(path=IDENT(name="sample"), expLst={start, interval}) then
  << >>
  else
    <<
    // UNKNOWN ZERO CROSSING for <%index1%>
    >>
end zeroCrossingTpl2;


template zeroCrossingsTpl(list<ZeroCrossing> zeroCrossings, Text &varDecls /*BUFP*/)
 "Generates code for zero crossings."
::=

  (zeroCrossings |> ZERO_CROSSING(__) hasindex i0 =>
    zeroCrossingTpl(i0, relation_, &varDecls /*BUFD*/)
  ;separator="\n")
end zeroCrossingsTpl;


template zeroCrossingTpl(Integer index1, Exp relation, Text &varDecls /*BUFP*/)
 "Generates code for a zero crossing."
::=
  match relation
  case RELATION(__) then
    let &preExp = buffer "" /*BUFD*/
    let e1 = daeExp(exp1, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let op = zeroCrossingOpFunc(operator)
    let e2 = daeExp(exp2, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    <<
    <%preExp%>
    ZEROCROSSING(<%index1%>, <%op%>(<%e1%>, <%e2%>));
    >>
  case CALL(path=IDENT(name="sample"), expLst={start, interval}) then
    let &preExp = buffer "" /*BUFD*/
    let e1 = daeExp(start, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let e2 = daeExp(interval, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    <<
    <%preExp%>
    ZEROCROSSING(<%index1%>,Sample(*t,<%e1%>,<%e2%>));
    >>
  else
    <<
    ZERO CROSSING ERROR
    >>
end zeroCrossingTpl;

template timeEventsTpl(list<SampleCondition> sampleConditions, Text &varDecls /*BUFP*/)
 "Generates code for zero crossings."
::=
  (sampleConditions |> (relation_,index)  =>
    timeEventTpl(index, relation_, &varDecls /*BUFD*/)
  ;separator="\n")
end timeEventsTpl;

template timeEventTpl(Integer index1, Exp relation, Text &varDecls /*BUFP*/)
 "Generates code for a zero crossing."
::=
  match relation
  case RELATION(__) then
    <<
    /* <%index1%> Not a time event */
    >>
  case CALL(path=IDENT(name="sample"), expLst={start, interval,_}) then
    let &preExp = buffer "" /*BUFD*/
    let e1 = daeExp(start, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let e2 = daeExp(interval, contextOther, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    <<
    <%preExp%>
    localData->rawSampleExps[i].start = <%e1%>;
    localData->rawSampleExps[i].interval = <%e2%>;
    localData->rawSampleExps[i++].zc_index = <%index1%>;
    >>
  else
    <<
    /* UNKNOWN ZERO CROSSING for <%index1%> */
    >>
end timeEventTpl;

template zeroCrossingOpFunc(Operator op)
 "Generates zero crossing function name for operator."
::=
  match op
  case LESS(__)      then "Less"
  case GREATER(__)   then "Greater"
  case LESSEQ(__)    then "LessEq"
  case GREATEREQ(__) then "GreaterEq"
end zeroCrossingOpFunc;


template equation_(SimEqSystem eq, Context context, Text &varDecls /*BUFP*/)
 "Generates an equation.
  This template should not be used for a SES_RESIDUAL.
  Residual equations are handled differently."
::=
  match eq
  case e as SES_SIMPLE_ASSIGN(__)
    then equationSimpleAssign(e, context, &varDecls /*BUFD*/)
  case e as SES_ARRAY_CALL_ASSIGN(__)
    then equationArrayCallAssign(e, context, &varDecls /*BUFD*/)
  case e as SES_ALGORITHM(__)
    then equationAlgorithm(e, context, &varDecls /*BUFD*/)
  case e as SES_LINEAR(__)
    then equationLinear(e, context, &varDecls /*BUFD*/)
  case e as SES_MIXED(__)
    then equationMixed(e, context, &varDecls /*BUFD*/)
  case e as SES_NONLINEAR(__)
    then equationNonlinear(e, context, &varDecls /*BUFD*/)
  case e as SES_WHEN(__)
    then equationWhen(e, context, &varDecls /*BUFD*/)
  else
    "NOT IMPLEMENTED EQUATION"
end equation_;


template inlineArray(Context context, String arr, ComponentRef c)
::= match context case INLINE_CONTEXT(__) then match c
case CREF_QUAL(ident = "$DER") then <<

inline_integrate_array(size_of_dimension_real_array(<%arr%>,1),<%cref(c)%>);
>>
end inlineArray;


template inlineVars(Context context, list<SimVar> simvars)
::= match context case INLINE_CONTEXT(__) then match simvars
case {} then ''
else <<

<%simvars |> var => match var case SIMVAR(name = cr as CREF_QUAL(ident = "$DER")) then 'inline_integrate(<%cref(cr)%>);' ;separator="\n"%>
>>
end inlineVars;


template inlineCrefs(Context context, list<ComponentRef> crefs)
::= match context case INLINE_CONTEXT(__) then match crefs
case {} then ''
else <<

<%crefs |> cr => match cr case CREF_QUAL(ident = "$DER") then 'inline_integrate(<%cref(cr)%>);' ;separator="\n"%>
>>
end inlineCrefs;


template inlineCref(Context context, ComponentRef cr)
::= match context case INLINE_CONTEXT(__) then match cr case CREF_QUAL(ident = "$DER") then <<

inline_integrate(<%cref(cr)%>);
>>
end inlineCref;


template equationSimpleAssign(SimEqSystem eq, Context context,
                              Text &varDecls /*BUFP*/)
 "Generates an equation that is just a simple assignment."
::=
match eq
case SES_SIMPLE_ASSIGN(__) then
  let &preExp = buffer "" /*BUFD*/
  let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  <<
  <%preExp%>
  <%cref(cref)%> = <%expPart%>; <%inlineCref(context,cref)%>
  >>
end equationSimpleAssign;


template equationArrayCallAssign(SimEqSystem eq, Context context,
                                 Text &varDecls /*BUFP*/)
 "Generates equation on form 'cref_array = call(...)'."
::=
match eq

case eqn as SES_ARRAY_CALL_ASSIGN(__) then
  let &preExp = buffer "" /*BUFD*/
  let expPart = daeExp(exp, context, &preExp /*BUF  let &preExp = buffer "" /*BUFD*/
  let &helpInits = buffer "" /*BUFD*/
  let helpIf = (conditions |> (e, hidx) =>
      let helpInit = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
      let &helpInits += 'localData->helpVars[<%hidx%>] = <%helpInit%>;'
      'edge(localData->helpVars[<%hidx%>])'
    ;separator=" || ")C*/, &varDecls /*BUFD*/)
  match expTypeFromExpShort(eqn.exp)
  case "boolean" then
    let tvar = tempDecl("boolean_array", &varDecls /*BUFD*/)
    //let &preExp += 'cast_integer_array_to_real(&<%expPart%>, &<%tvar%>);<%\n%>'
    <<
    <%preExp%>
    copy_boolean_array_data_mem(&<%expPart%>, &<%cref(eqn.componentRef)%>);<%inlineArray(context,tvar,eqn.componentRef)%>
    >>
  case "integer" then
    let tvar = tempDecl("integer_array", &varDecls /*BUFD*/)
    let &preExp += 'cast_integer_array_to_real(&<%expPart%>, &<%tvar%>);<%\n%>'
    <<
    <%preExp%>
    copy_integer_array_data_mem(&<%expPart%>, &<%cref(eqn.componentRef)%>);<%inlineArray(context,tvar,eqn.componentRef)%>
    >>
  case "real" then
    <<
    <%preExp%>
    copy_real_array_data_mem(&<%expPart%>, &<%cref(eqn.componentRef)%>);<%inlineArray(context,expPart,eqn.componentRef)%>
    >>
  else "#error \"No runtime support for this sort of array call\""
end equationArrayCallAssign;


template equationAlgorithm(SimEqSystem eq, Context context, Text &varDecls /*BUFP*/)
 "Generates an equation that is an algorithm."
::=
match eq
case SES_ALGORITHM(__) then
  (statements |> stmt =>
    algStatement(stmt, context, &varDecls /*BUFD*/)
  ;separator="\n") 
end equationAlgorithm;


template equationLinear(SimEqSystem eq, Context context, Text &varDecls /*BUFP*/)
 "Generates a linear equation system."
::=
match eq
case SES_LINEAR(__) then
  let uid = System.tmpTick()
  let size = listLength(vars)
  let aname = 'A<%uid%>'
  let bname = 'b<%uid%>'
  let mixedPostfix = if partOfMixed then "_mixed" //else ""
  <<
  <% if not partOfMixed then 'SIM_PROF_TICK_EQ(SIM_PROF_EQ_<%index%>);<%\n%>' %>
  declare_matrix(<%aname%>, <%size%>, <%size%>);
  declare_vector(<%bname%>, <%size%>);
  <%simJac |> (row, col, eq as SES_RESIDUAL(__)) =>
     let &preExp = buffer "" /*BUFD*/
     let expPart = daeExp(eq.exp, context, &preExp /*BUFC*/,  &varDecls /*BUFD*/)
     '<%preExp%>set_matrix_elt(<%aname%>, <%row%>, <%col%>, <%size%>, <%expPart%>);'
  ;separator="\n"%>
  <%beqs |> exp hasindex i0 =>
     let &preExp = buffer "" /*BUFD*/
     let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
     '<%preExp%>set_vector_elt(<%bname%>, <%i0%>, <%expPart%>);'
  ;separator="\n"%>
  solve_linear_equation_system<%mixedPostfix%>(<%aname%>, <%bname%>, <%size%>, <%uid%>);
  <%vars |> SIMVAR(__) hasindex i0 => '<%cref(name)%> = get_vector_elt(<%bname%>, <%i0%>);' ;separator="\n"%><%inlineVars(context,vars)%>
  <% if not partOfMixed then 'SIM_PROF_ACC_EQ(SIM_PROF_EQ_<%index%>);<%\n%>' %>
  >>
end equationLinear;


template equationMixed(SimEqSystem eq, Context context, Text &varDecls /*BUFP*/)
 "Generates a mixed equation system."
::=
match eq
case SES_MIXED(__) then
  let contEqs = equation_(cont, context, &varDecls /*BUFD*/)
  let numDiscVarsStr = listLength(discVars) 
  let valuesLenStr = listLength(values)
  let &preDisc = buffer "" /*BUFD*/
  let discLoc2 = (discEqs |> SES_SIMPLE_ASSIGN(__) hasindex i0 =>
      let expPart = daeExp(exp, context, &preDisc /*BUFC*/, &varDecls /*BUFD*/)
      <<
      <%cref(cref)%> = <%expPart%>;
      discrete_loc2[<%i0%>] = <%cref(cref)%>;
      >>
    ;separator="\n")
  <<
  SIM_PROF_TICK_EQ(SIM_PROF_EQ_<%index%>);
  mixed_equation_system(<%numDiscVarsStr%>);
  double values[<%valuesLenStr%>] = {<%values ;separator=", "%>};
  int value_dims[<%numDiscVarsStr%>] = {<%value_dims ;separator=", "%>};
  <%discVars |> SIMVAR(__) hasindex i0 => 'discrete_loc[<%i0%>] = <%cref(name)%>;' ;separator="\n"%>
  {
    <%contEqs%>
  }
  <%preDisc%>
  <%discLoc2%>
  {
    double *loc_ptrs[<%numDiscVarsStr%>] = {<%discVars |> SIMVAR(__) => '(double*)&<%cref(name)%>' ;separator=", "%>};
    check_discrete_values(<%numDiscVarsStr%>, <%valuesLenStr%>);
  }
  mixed_equation_system_end(<%numDiscVarsStr%>);
  SIM_PROF_ACC_EQ(SIM_PROF_EQ_<%index%>);
  >>
end equationMixed;


template equationNonlinear(SimEqSystem eq, Context context, Text &varDecls /*BUFP*/)
 "Generates a non linear equation system."
::=
match eq
case SES_NONLINEAR(__) then
  let size = listLength(crefs)
  <<
  start_nonlinear_system(<%size%>);
  <%crefs |> name hasindex i0 =>
    <<
    nls_x[<%i0%>] = extraPolate(<%cref(name)%>);
    nls_xold[<%i0%>] = $P$old<%cref(name)%>;
    >>
  ;separator="\n"%>
  solve_nonlinear_system(residualFunc<%index%>, <%reverseLookupEquationNumber(index)%>);
  <%crefs |> name hasindex i0 => '<%cref(name)%> = nls_x[<%i0%>];' ;separator="\n"%>
  end_nonlinear_system();<%inlineCrefs(context,crefs)%>
  >>
end equationNonlinear;

template reverseLookupEquationNumber(Integer index)
::=
  'localData->equationInfo[omc_equationInfo_reverse_prof_index[SIM_PROF_EQ_<%index%>]]'
end reverseLookupEquationNumber;

template equationWhen(SimEqSystem eq, Context context, Text &varDecls /*BUFP*/)
 "Generates a when equation."
::=
match eq
case SES_WHEN(left=left, right=right,conditions=conditions,elseWhen = NONE()) then
  let &preExp = buffer "" /*BUFD*/
  let &helpInits = buffer "" /*BUFD*/
  let helpIf = (conditions |> (e, hidx) =>
      let helpInit = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
      let &helpInits += 'localData->helpVars[<%hidx%>] = <%helpInit%>;'
      'edge(localData->helpVars[<%hidx%>])'
    ;separator=" || ")
  let &preExp2 = buffer "" /*BUFD*/
  let exp = daeExp(right, context, &preExp2 /*BUFC*/, &varDecls /*BUFD*/)
  <<
  <%preExp%>
  <%helpInits%>
  if (<%helpIf%>) {
    <%preExp2%>
    <%cref(left)%> = <%exp%>;
  } else {
    <%cref(left)%> = pre(<%cref(left)%>);
  }
  >>
  case SES_WHEN(left=left, right=right,conditions=conditions,elseWhen = SOME(elseWhenEq)) then
  let &preExp = buffer "" /*BUFD*/
  let &helpInits = buffer "" /*BUFD*/
  let helpIf = (conditions |> (e, hidx) =>
      let helpInit = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
      let &helpInits += 'localData->helpVars[<%hidx%>] = <%helpInit%>;'
      'edge(localData->helpVars[<%hidx%>])'
    ;separator=" || ")
  let &preExp2 = buffer "" /*BUFD*/
  let exp = daeExp(right, context, &preExp2 /*BUFC*/, &varDecls /*BUFD*/)
  let elseWhen = equationElseWhen(elseWhenEq,context,preExp,helpInits, varDecls)
  <<
  <%preExp%>
  <%helpInits%>
  if (<%helpIf%>) {
    <%preExp2%>
    <%cref(left)%> = <%exp%>;
  }
  <%elseWhen%>
  else {
    <%cref(left)%> = pre(<%cref(left)%>);
  }
  >> 
end equationWhen;

template equationElseWhen(SimEqSystem eq, Context context, Text &preExp /*BUFD*/, Text &helpInits /*BUFD*/, Text &varDecls /*BUFP*/)
 "Generates a else when equation."
::=
match eq
case SES_WHEN(left=left, right=right,conditions=conditions,elseWhen = NONE()) then
  let helpIf = (conditions |> (e, hidx) =>
      let helpInit = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
      let &helpInits += 'localData->helpVars[<%hidx%>] = <%helpInit%>;'
      'edge(localData->helpVars[<%hidx%>])'
    ;separator=" || ")
  let &preExp2 = buffer "" /*BUFD*/
  let exp = daeExp(right, context, &preExp2 /*BUFC*/, &varDecls /*BUFD*/)
  <<
  else if (<%helpIf%>) {
    <%preExp2%>
    <%cref(left)%> = <%exp%>;
  }
  >>
case SES_WHEN(left=left, right=right,conditions=conditions,elseWhen = SOME(elseWhenEq)) then
  let helpIf = (conditions |> (e, hidx) =>
      let helpInit = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
      let &helpInits += 'localData->helpVars[<%hidx%>] = <%helpInit%>;'
      'edge(localData->helpVars[<%hidx%>])'
    ;separator=" || ")
  let &preExp2 = buffer "" /*BUFD*/
  let exp = daeExp(right, context, &preExp2 /*BUFC*/, &varDecls /*BUFD*/)
  let elseWhen = equationElseWhen(elseWhenEq,context,preExp,helpInits, varDecls)
  <<
  else if (<%helpIf%>) {
    <%preExp2%>
    <%cref(left)%> = <%exp%>;
  }
  <%elseWhen%>
  >>  
end equationElseWhen;

template simulationFunctionsFile(String filePrefix, list<Function> functions, list<Exp> literals)
 "Generates the content of the C file for functions in the simulation case."
::=
  <<
  #include "<%filePrefix%>_functions.h"
  extern "C" {
  
  <%literals |> literal hasindex i0 from 0 => literalExpConst(literal,i0) ; separator="\n"%>

  <%functionBodies(functions)%>
  }
  
  >>
  /* adpro: leave a newline at the end of file to get rid of warnings! */
end simulationFunctionsFile;

template recordsFile(String filePrefix, list<RecordDeclaration> recordDecls)
 "Generates the content of the C file for functions in the simulation case."
::=
  <<
  /* Additional record code for <%filePrefix%> generated by the OpenModelica Compiler <%getVersionNr()%>. */
  #include "meta_modelica.h"
  <%recordDecls |> rd => recordDeclaration(rd) ;separator="\n"%>
  
  >>
  /* adpro: leave a newline at the end of file to get rid of warnings! */
end recordsFile;

template simulationFunctionsHeaderFile(String filePrefix, list<Function> functions, list<String> includes, list<RecordDeclaration> recordDecls)
 "Generates the content of the C file for functions in the simulation case."
::=
  <<
  #ifndef <%stringReplace(filePrefix,".","_")%>__H
  #define <%stringReplace(filePrefix,".","_")%>__H
  <%commonHeader()%>
  #include "simulation_runtime.h"
  extern "C" {
  <%recordDecls |> rd => recordDeclarationHeader(rd) ;separator="\n"%>
  <%externalFunctionIncludes(includes)%>
  <%functionHeaders(functions)%>
  }
  #endif
  
  <%\n%> 
  >>
  /* adrpo: leave a newline at the end of file to get rid of the warning */
end simulationFunctionsHeaderFile;


template simulationMakefile(SimCode simCode)
 "Generates the contents of the makefile for the simulation case."
::=
match simCode
case SIMCODE(modelInfo=MODELINFO(__), makefileParams=MAKEFILE_PARAMS(__)) then
  let dirExtra = if modelInfo.directory then '-L"<%modelInfo.directory%>"' //else ""
  let libsStr = (makefileParams.libs |> lib => lib ;separator=" ")
  let libsPos1 = if not dirExtra then libsStr //else ""
  let libsPos2 = if dirExtra then libsStr // else ""
  <<
  # Makefile generated by OpenModelica
  
  CC=<%makefileParams.ccompiler%>
  CXX=<%makefileParams.cxxcompiler%>
  LINK=<%makefileParams.linker%>
  EXEEXT=<%makefileParams.exeext%>
  DLLEXT=<%makefileParams.dllext%>
  CFLAGS=-I"<%makefileParams.omhome%>/include/omc" <%makefileParams.cflags%>
  LDFLAGS=-L"<%makefileParams.omhome%>/lib/omc" <%makefileParams.ldflags%>
  SENDDATALIBS=<%makefileParams.senddatalibs%>
  
  .PHONY: <%fileNamePrefix%>
  <%fileNamePrefix%>: <%fileNamePrefix%>.cpp <%fileNamePrefix%>_functions.cpp <%fileNamePrefix%>_functions.h <%fileNamePrefix%>_records.c
  <%\t%> $(CXX) -I. -o <%fileNamePrefix%>$(EXEEXT) <%fileNamePrefix%>.cpp <%fileNamePrefix%>_functions.cpp <%dirExtra%> <%libsPos1%> <%libsPos2%> -lsim -linteractive $(CFLAGS) $(SENDDATALIBS) $(LDFLAGS) -lf2c <%fileNamePrefix%>_records.c 
  >>
end simulationMakefile;


template simulationInitFile(SimCode simCode)
 "Generates the contents of the makefile for the simulation case."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(varInfo = vi as VARINFO(__), vars = vars as SIMVARS(__)), 
             simulationSettingsOpt = SOME(s as SIMULATION_SETTINGS(__))) 
  then
  <<
  <%s.startTime%> // start value
  <%s.stopTime%> // stop value
  <%s.stepSize%> // step value
  <%s.tolerance%> // tolerance
  "<%s.method%>" // method
  "<%s.outputFormat%>" // outputFormat
  <%vi.numStateVars%> // n states
  <%vi.numAlgVars%> // n alg vars
  <%vi.numParams%> //n parameters
  <%vi.numIntParams%> // n int parameters
  <%vi.numIntAlgVars%> // n int variables
  <%vi.numBoolParams%> // n bool parameters
  <%vi.numBoolAlgVars%> // n bool variables
  <%vi.numStringParamVars%> // n string-parameters
  <%vi.numStringAlgVars%> // n string variables
  <%initVals(vars.stateVars)%>
  <%initVals(vars.derivativeVars)%>
  <%initVals(vars.algVars)%>
  <%initVals(vars.paramVars)%>
  <%initVals(vars.intParamVars)%>
  <%initVals(vars.intAlgVars)%>
  <%initVals(vars.boolParamVars)%>
  <%initVals(vars.boolAlgVars)%>    
  <%initVals(vars.stringParamVars)%>
  <%initVals(vars.stringAlgVars)%>  
  >>
end simulationInitFile;

template initVals(list<SimVar> varsLst) ::=
  varsLst |> SIMVAR(__) =>
  <<
  <%match initialValue 
    case SOME(v) then initVal(v)
      else "0.0 //default"
    %> //<%crefStr(name)%>
    >>  
  ;separator="\n"
end initVals;

template initVal(Exp initialValue) 
::=
  match initialValue 
  case ICONST(__) then integer
  case RCONST(__) then real
  case SCONST(__) then '"<%Util.escapeModelicaStringToCString(string)%>"'
  case BCONST(__) then if bool then "true" else "false"
  case ENUM_LITERAL(__) then '<%index%>/*ENUM:<%dotPath(name)%>*/'
  else "*ERROR* initial value of unknown type"
end initVal;

template commonHeader()
::=
  <<
  <% if acceptMetaModelicaGrammar() then '#define __OPENMODELICA__METAMODELICA'%>
  #include "modelica.h"
  #include <stdio.h>
  #include <stdlib.h>
  #include <errno.h>
  
  #if defined(_MSC_VER)
    #define DLLExport   __declspec( dllexport )
  #else
    #define DLLExport /* nothing */
  #endif
  >>
end commonHeader;

template functionsFile(String filePrefix,
                       Option<Function> mainFunction,
                       list<Function> functions,
                       list<Exp> literals)
 "Generates the contents of the main C file for the function case."
::=
  <<
  #include "<%filePrefix%>.h"
  #include <algorithm>
  #define MODELICA_ASSERT(info,msg) { printInfo(stderr,info); fprintf(stderr,"Modelica Assert: %s!\n", msg); }
  #define MODELICA_TERMINATE(msg) { fprintf(stderr,"Modelica Terminate: %s!\n", msg); fflush(stderr); }

  extern "C" {
  
  <%literals |> literal hasindex i0 from 0 => literalExpConst(literal,i0) ; separator="\n"%>
  
  <%match mainFunction case SOME(fn) then functionBody(fn,true)%>
  <%functionBodies(functions)%>
  }
  
  >>
end functionsFile;

template functionsHeaderFile(String filePrefix,
                       Option<Function> mainFunction,
                       list<Function> functions,
                       list<RecordDeclaration> extraRecordDecls,
                       list<String> includes)
 "Generates the contents of the main C file for the function case."
::=
  <<
  #ifndef <%stringReplace(filePrefix,".","_")%>__H
  #define <%stringReplace(filePrefix,".","_")%>__H
  <%commonHeader()%>
  #ifdef __cplusplus
  extern "C" {
  #endif
  
  <%externalFunctionIncludes(includes)%>
  <%extraRecordDecls |> rd => recordDeclarationHeader(rd) ;separator="\n"%>
  <%match mainFunction case SOME(fn) then functionHeader(fn,true)%>
  <%functionHeaders(functions)%>

  #ifdef __cplusplus
  }
  #endif
  #endif
  
  <%\n%> 
  >>
  /* adrpo: leave a newline at the end of file to get rid of the warning */
end functionsHeaderFile;

template functionsMakefile(FunctionCode fnCode)
 "Generates the contents of the makefile for the function case."
::=
match fnCode
case FUNCTIONCODE(makefileParams=MAKEFILE_PARAMS(__)) then
  let libsStr = (makefileParams.libs ;separator=" ")
  <<
  # Makefile generated by OpenModelica
  
  CC=<%makefileParams.ccompiler%>
  CXX=<%makefileParams.cxxcompiler%>
  LINK=<%makefileParams.linker%>
  EXEEXT=<%makefileParams.exeext%>
  DLLEXT=<%makefileParams.dllext%>
  CFLAGS= -I"<%makefileParams.omhome%>/include/omc" <%makefileParams.cflags%>
  LDFLAGS= -L"<%makefileParams.omhome%>/lib/omc" <%makefileParams.ldflags%>
  SENDDATALIBS=<%makefileParams.senddatalibs%>
  
  .PHONY: <%name%>
  <%name%>: <%name%>.c <%name%>.h <%name%>_records.c
  <%\t%> $(LINK) -o <%name%>$(DLLEXT) <%name%>.c <%libsStr%> $(CFLAGS) $(LDFLAGS) $(SENDDATALIBS) -lm <%name%>_records.c 
  >>
end functionsMakefile;

template contextCref(ComponentRef cr, Context context)
  "Generates code for a component reference depending on which context we're in."
::=
  match context
  case FUNCTION_CONTEXT(__) then "_" + crefStr(cr)
  else cref(cr)
end contextCref;

template contextIteratorName(Ident name, Context context)
  "Generates code for an iterator variable."
::=
  match context
  case FUNCTION_CONTEXT(__) then "_" + name
  else "$P" + name
end contextIteratorName;

template cref(ComponentRef cr)
 "Generates C equivalent name for component reference."
::=
  match cr
  case CREF_IDENT(ident = "xloc") then crefStr(cr)
  case CREF_IDENT(ident = "time") then "time"
  case WILD(__) then ''
  else "$P" + crefToCStr(cr)
end cref;

template crefToCStr(ComponentRef cr)
 "Helper function to cref."
::=
  match cr
  case CREF_IDENT(__) then '<%ident%><%subscriptsToCStr(subscriptLst)%>'
  case CREF_QUAL(__) then '<%ident%><%subscriptsToCStr(subscriptLst)%>$P<%crefToCStr(componentRef)%>'
  case WILD(__) then ''
  else "CREF_NOT_IDENT_OR_QUAL"
end crefToCStr;

template subscriptsToCStr(list<Subscript> subscripts)
::=
  if subscripts then
    '$lB<%subscripts |> s => subscriptToCStr(s) ;separator="$c"%>$rB'
end subscriptsToCStr;

template subscriptToCStr(Subscript subscript)
::=
  match subscript
  case INDEX(exp=ICONST(integer=i)) then i
  case SLICE(exp=ICONST(integer=i)) then i
  case WHOLEDIM(__) then "WHOLEDIM"
  else "UNKNOWN_SUBSCRIPT"
end subscriptToCStr;

template crefStr(ComponentRef cr)
 "Generates the name of a variable for variable name array."
::=
  match cr
  case CREF_IDENT(__) then '<%ident%><%subscriptsStr(subscriptLst)%>'
  // Are these even needed? Function context should only have CREF_IDENT :)
  case CREF_QUAL(ident = "$DER") then 'der(<%crefStr(componentRef)%>)'
  case CREF_QUAL(__) then '<%ident%><%subscriptsStr(subscriptLst)%>.<%crefStr(componentRef)%>'
  else "CREF_NOT_IDENT_OR_QUAL"
end crefStr;

template crefM(ComponentRef cr)
 "Generates Modelica equivalent name for component reference."
::=
  match cr
  case CREF_IDENT(ident = "xloc") then crefStr(cr)
  case CREF_IDENT(ident = "time") then "time"
  else "P" + crefToMStr(cr)
end crefM;

template crefToMStr(ComponentRef cr)
 "Helper function to crefM."
::=
  match cr
  case CREF_IDENT(__) then '<%ident%><%subscriptsToMStr(subscriptLst)%>'
  case CREF_QUAL(__) then '<%ident%><%subscriptsToMStr(subscriptLst)%>P<%crefToMStr(componentRef)%>'
  else "CREF_NOT_IDENT_OR_QUAL"
end crefToMStr;





template subscriptsToMStr(list<Subscript> subscripts)
::=
  if subscripts then
    'lB<%subscripts |> s => subscriptToMStr(s) ;separator="c"%>rB'
end subscriptsToMStr;

template subscriptToMStr(Subscript subscript)
::=
  let &preExp = buffer ""
  let &varDecls = buffer ""
  match subscript
  case INDEX(__)
  case SLICE(__) then daeExp(exp, contextSimulationNonDiscrete, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case WHOLEDIM(__) then "WHOLEDIM"
  else "UNKNOWN_SUBSCRIPT"
end subscriptToMStr;


template contextArrayCref(ComponentRef cr, Context context)
 "Generates code for an array component reference depending on the context."
::=
  match context
  case FUNCTION_CONTEXT(__) then "_" + arrayCrefStr(cr)
  else arrayCrefCStr(cr)
end contextArrayCref;

template arrayCrefCStr(ComponentRef cr)
::= '$P<%arrayCrefCStr2(cr)%>'
end arrayCrefCStr;

template arrayCrefCStr2(ComponentRef cr)
::=
  match cr
  case CREF_IDENT(__) then '<%ident%>'
  case CREF_QUAL(__) then '<%ident%>$P<%arrayCrefCStr2(componentRef)%>'
  else "CREF_NOT_IDENT_OR_QUAL"
end arrayCrefCStr2;

template arrayCrefStr(ComponentRef cr)
::=
  match cr
  case CREF_IDENT(__) then '<%ident%>'
  case CREF_QUAL(__) then '<%ident%>.<%arrayCrefStr(componentRef)%>'
  else "CREF_NOT_IDENT_OR_QUAL"
end arrayCrefStr;

template subscriptsStr(list<Subscript> subscripts)
 "Generares subscript part of the name."
::=
  if subscripts then
    '[<%subscripts |> s => subscriptStr(s) ;separator=","%>]'
end subscriptsStr;

template subscriptStr(Subscript subscript)
 "Generates a single subscript.
  Only works for constant integer indicies."

::=
  match subscript
  case INDEX(exp=ICONST(integer=i)) then i
  case SLICE(exp=ICONST(integer=i)) then i
  case WHOLEDIM(__) then "WHOLEDIM"
  else "UNKNOWN_SUBSCRIPT"
end subscriptStr;

template expCref(DAE.Exp ecr)
::=
  match ecr
  case CREF(__) then cref(componentRef)
  case CALL(path = IDENT(name = "der"), expLst = {arg as CREF(__)}) then
    '$P$DER<%cref(arg.componentRef)%>'
  else "ERROR_NOT_A_CREF"
end expCref;

template crefFunctionName(ComponentRef cr)
::=
  match cr
  case CREF_IDENT(__) then 
    System.stringReplace(ident, "_", "__")
  case CREF_QUAL(__) then 
    '<%System.stringReplace(ident, "_", "__")%>_<%crefFunctionName(componentRef)%>'
end crefFunctionName;

template dotPath(Path path)
 "Generates paths with components separated by dots."
::=
  match path
  case QUALIFIED(__)      then '<%name%>.<%dotPath(path)%>'

  case IDENT(__)          then name
  case FULLYQUALIFIED(__) then dotPath(path)
end dotPath;

template replaceDotAndUnderscore(String str)
 "Replace _ with __ and dot in identifiers with _"
::=
  match str
  case name then
    let str_dots = System.stringReplace(name,".", "_")  
    let str_underscores = System.stringReplace(str_dots, "_", "__")
    '<%str_underscores%>'
end replaceDotAndUnderscore;

template underscorePath(Path path)
 "Generate paths with components separated by underscores.
  Replaces also the . in identifiers with _. 
  The dot might happen for world.gravityAccleration"
::=
  match path
  case QUALIFIED(__) then
    '<%replaceDotAndUnderscore(name)%>_<%underscorePath(path)%>'
  case IDENT(__) then
    replaceDotAndUnderscore(name)
  case FULLYQUALIFIED(__) then
    underscorePath(path)
end underscorePath;


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


template functionHeaders(list<Function> functions)
 "Generates function header part in function files."
::=
  (functions |> fn => functionHeader(fn, false) ; separator="\n")
end functionHeaders;

template functionHeader(Function fn, Boolean inFunc)
 "Generates function header part in function files."
::=
  match fn
    case FUNCTION(__) then
      <<
      <%functionHeaderNormal(underscorePath(name), functionArguments, outVars, inFunc)%>
      <%functionHeaderBoxed(underscorePath(name), functionArguments, outVars, isBoxedFunction(fn))%>
      >> 
    case EXTERNAL_FUNCTION(__) then
      <<
      <%functionHeaderNormal(underscorePath(name), funArgs, outVars, inFunc)%>
      <%functionHeaderBoxed(underscorePath(name), funArgs, outVars, isBoxedFunction(fn))%>
  
      <%extFunDef(fn)%>
      >> 
    case RECORD_CONSTRUCTOR(__) then
      let fname = underscorePath(name)
      let funArgsStr = (funArgs |> var as VARIABLE(__) =>
          '<%varType(var)%> <%crefStr(name)%>'
        ;separator=", ")
      let funArgsBoxedStr = if acceptMetaModelicaGrammar() then
          (funArgs |> var => funArgBoxedDefinition(var) ;separator=", ")
      let boxedHeader = if acceptMetaModelicaGrammar() then
        <<
        modelica_metatype boxptr_<%fname%>(<%funArgsBoxedStr%>);
        >>
      <<
      #define <%fname%>_rettype_1 targ1
      typedef struct <%fname%>_rettype_s {
        struct <%fname%> targ1;
      } <%fname%>_rettype;
      
      <%fname%>_rettype _<%fname%>(<%funArgsStr%>);

      <%boxedHeader%>
      >> 
end functionHeader;

template recordDeclaration(RecordDeclaration recDecl)
 "Generates structs for a record declaration."
::=
  match recDecl
  case RECORD_DECL_FULL(__) then
    <<
    <%recordDefinition(dotPath(defPath),
                      underscorePath(defPath),
                      (variables |> VARIABLE(__) => '"<%crefStr(name)%>"' ;separator=","),
                      listLength(variables))%>
    >> 
  case RECORD_DECL_DEF(__) then
    <<
    <%recordDefinition(dotPath(path),
                      underscorePath(path),
                      (fieldNames |> name => '"<%name%>"' ;separator=","),
                      listLength(fieldNames))%>
    >>
end recordDeclaration;

template recordDeclarationHeader(RecordDeclaration recDecl)
 "Generates structs for a record declaration."
::=
  match recDecl
  case RECORD_DECL_FULL(__) then
    <<
    struct <%name%> {
      <%variables |> var as VARIABLE(__) => '<%varType(var)%> <%crefStr(var.name)%>;' ;separator="\n"%>
    };
    <%recordDefinitionHeader(dotPath(defPath),
                      underscorePath(defPath),
                      listLength(variables))%>
    >> 
  case RECORD_DECL_DEF(__) then
    <<
    <%recordDefinitionHeader(dotPath(path),
                      underscorePath(path),
                      listLength(fieldNames))%>
    >>
end recordDeclarationHeader;

template recordDefinition(String origName, String encName, String fieldNames, Integer numFields)
 "Generates the definition struct for a record declaration."
::=
  <<
  #define <%encName%>__desc_added 1
  const char* <%encName%>__desc__fields[<%numFields%>] = {<%fieldNames%>};
  struct record_description <%encName%>__desc = {
    "<%encName%>", /* package_record__X */
    "<%origName%>", /* package.record_X */
    <%encName%>__desc__fields
  };
  >>
end recordDefinition;

template recordDefinitionHeader(String origName, String encName, Integer numFields)
 "Generates the definition struct for a record declaration."
::=
  <<
  extern struct record_description <%encName%>__desc;
  >>
end recordDefinitionHeader;

template functionHeaderNormal(String fname, list<Variable> fargs, list<Variable> outVars, Boolean inFunc)
::= functionHeaderImpl(fname, fargs, outVars, inFunc, false)
end functionHeaderNormal;

template functionHeaderBoxed(String fname, list<Variable> fargs, list<Variable> outVars, Boolean isBoxed)
::= if acceptMetaModelicaGrammar() then
    if isBoxed then '#define boxptr_<%fname%> _<%fname%><%\n%>' else functionHeaderImpl(fname, fargs, outVars, false, true)
end functionHeaderBoxed;

template functionHeaderImpl(String fname, list<Variable> fargs, list<Variable> outVars, Boolean inFunc, Boolean boxed)
 "Generates function header for a Modelica/MetaModelica function. Generates a

  boxed version of the header if boxed = true, otherwise a normal header"
::=
  let fargsStr = if boxed then 
      (fargs |> var => funArgBoxedDefinition(var) ;separator=", ") 
    else 
      (fargs |> var => funArgDefinition(var) ;separator=", ")
  let boxStr = if boxed then "boxed"
  let boxPtrStr = if boxed then "boxptr"
  let inFnStr = if boxed then "" else if inFunc then
    <<

    DLLExport 
    int in_<%fname%>(type_description * inArgs, type_description * outVar);
    >>
  if outVars then <<
  <%outVars |> _ hasindex i1 from 1 => '#define <%fname%>_rettype<%boxStr%>_<%i1%> targ<%i1%>' ;separator="\n"%>
  typedef struct <%fname%>_rettype<%boxStr%>_s 
  {
    <%outVars |> var hasindex i1 from 1 =>
      match var
      case VARIABLE(__) then
        let dimStr = match ty case ET_ARRAY(__) then
          '[<%arrayDimensions |> dim => dimension(dim) ;separator=", "%>]'
        let typeStr = if boxed then varTypeBoxed(var) else varType(var) 
        '<%typeStr%> targ<%i1%>; /* <%crefStr(name)%><%dimStr%> */'
      case FUNCTION_PTR(__) then
        'modelica_fnptr targ<%i1%>; /* <%name%> */'
      ;separator="\n"
    %>
  } <%fname%>_rettype<%boxStr%>;
  <%inFnStr%>

  <%fname%>_rettype<%boxStr%> <%boxPtrStr%>_<%fname%>(<%fargsStr%>);
  >> else <<

  void <%boxPtrStr%>_<%fname%>(<%fargsStr%>);
  >>
end functionHeaderImpl;

template funArgName(Variable var)
::=
  match var
  case VARIABLE(__) then contextCref(name,contextFunction)
  case FUNCTION_PTR(__) then name
end funArgName;

template funArgDefinition(Variable var)
::=
  match var
  case VARIABLE(__) then '<%varType(var)%> <%contextCref(name,contextFunction)%>'
  case FUNCTION_PTR(__) then 'modelica_fnptr <%name%>'
end funArgDefinition;

template funArgBoxedDefinition(Variable var)
 "A definition for a boxed variable is always of type modelica_metatype, 
  unless it's a function pointer"
::=
  match var
  case VARIABLE(__) then 'modelica_metatype <%contextCref(name,contextFunction)%>'
  case FUNCTION_PTR(__) then 'modelica_fnptr <%name%>'
end funArgBoxedDefinition;

template extFunDef(Function fn)
 "Generates function header for an external function."
::=
match fn
case func as EXTERNAL_FUNCTION(__) then
  let fn_name = extFunctionName(extName, language)
  let fargsStr = extFunDefArgs(extArgs, language)
  'extern <%extReturnType(extReturn)%> <%fn_name%>(<%fargsStr%>);'
end extFunDef;

template extFunctionName(String name, String language)
::=
  match language
  case "C" then '<%name%>'
  case "FORTRAN 77" then '<%name%>_'
  else '<%\n%>#error "UNSUPPORTED_LANGUAGE: <%language%>"<%\n%>'
end extFunctionName;

template extFunDefArgs(list<SimExtArg> args, String language)
::=
  match language
  case "C" then (args |> arg => extFunDefArg(arg) ;separator=", ")
  case "FORTRAN 77" then (args |> arg => extFunDefArgF77(arg) ;separator=", ")
  else '<%\n%>#error "UNSUPPORTED_LANGUAGE: <%language%>"<%\n%>'
end extFunDefArgs;

template extReturnType(SimExtArg extArg)
 "Generates return type for external function."
::=
  match extArg
  case SIMEXTARG(__)   then extType(type_)
  case SIMNOEXTARG(__) then "void"
end extReturnType;


template extType(ExpType type)
 "Generates type for external function argument or return value."
::=
  match type
  case ET_INT(__)         then "int"
  case ET_REAL(__)        then "double"
  case ET_STRING(__)      then "const char*"
  case ET_BOOL(__)        then "int"
  case ET_ENUMERATION(__) then "int"  
  case ET_ARRAY(__)       then extType(ty)
  case ET_COMPLEX(complexClassType=EXTERNAL_OBJ(__))
                      then "void *"
  case ET_COMPLEX(complexClassType=RECORD(path=rname))
                      then 'struct <%underscorePath(rname)%>'
  case ET_METATYPE(__) case ET_BOXED(__)    then "void*"
  else "OTHER_EXT_TYPE"
end extType;


template extFunDefArg(SimExtArg extArg)
 "Generates the definition of an external function argument.
  Assume that language is C for now."
::=
  match extArg
  case SIMEXTARG(cref=c, isInput=ii, isArray=ia, type_=t) then
    let name = contextCref(c,contextFunction)
    let typeStr = if ii then
        if ia then
          match extType(t) 
          case "const char*" then // For string arrays
            'const char* const *'
          else
            'const <%extType(t)%> *'
        else
          '<%extType(t)%>'
      else
        '<%extType(t)%>*'
    <<
    <%typeStr%> <%name%>
    >>
  case SIMEXTARGEXP(__) then
    let typeStr = extType(type_)
    <<
    <%typeStr%>
    >>
  case SIMEXTARGSIZE(cref=c) then
    <<
    size_t
    >>
end extFunDefArg;

template extFunDefArgF77(SimExtArg extArg)
::= 
  match extArg
  case SIMEXTARG(cref=c, isInput = true, type_=t) then
    let name = contextCref(c,contextFunction)
    let typeStr = 'const <%extType(t)%> *'
    '<%typeStr%> <%name%>'
  case SIMEXTARG(__) then extFunDefArg(extArg)

  case SIMEXTARGEXP(__) then extFunDefArg(extArg)
  case SIMEXTARGSIZE(__) then 'int const *'
end extFunDefArgF77;


template functionName(Function fn, Boolean dotPath)
::=
  match fn
  case FUNCTION(__)
  case EXTERNAL_FUNCTION(__)
  case RECORD_CONSTRUCTOR(__) then if dotPath then dotPath(name) else underscorePath(name)
end functionName;


template functionBodies(list<Function> functions)
 "Generates the body for a set of functions."
::=
  (functions |> fn => functionBody(fn, false) ;separator="\n")
end functionBodies;


template functionBody(Function fn, Boolean inFunc)
 "Generates the body for a function."
::=
  match fn
  case fn as FUNCTION(__)           then functionBodyRegularFunction(fn, inFunc)
  case fn as EXTERNAL_FUNCTION(__)  then functionBodyExternalFunction(fn, inFunc)
  case fn as RECORD_CONSTRUCTOR(__) then functionBodyRecordConstructor(fn)
end functionBody;


template functionBodyRegularFunction(Function fn, Boolean inFunc)
 "Generates the body for a Modelica/MetaModelica function."
::=
match fn
case FUNCTION(__) then
  let()= System.tmpTickReset(1)
  let fname = underscorePath(name)
  let retType = if outVars then '<%fname%>_rettype' else "void"
  let &varDecls = buffer "" /*BUFD*/
  let &varInits = buffer "" /*BUFD*/
  let retVar = if outVars then tempDecl(retType, &varDecls /*BUFD*/)
  let stateVar = if not acceptMetaModelicaGrammar() then tempDecl("state", &varDecls /*BUFD*/)
  let _ = (variableDeclarations |> var hasindex i1 from 1 =>
      varInit(var, "", i1, &varDecls /*BUFD*/, &varInits /*BUFC*/)
    )
  let funArgs = (functionArguments |> var => functionArg(var, &varInits) ;separator="\n")
  let bodyPart = (body |> stmt  => funStatement(stmt, &varDecls /*BUFD*/) ;separator="\n")
  let &outVarInits = buffer ""
  let &outVarCopy = buffer ""
  let &outVarAssign = buffer ""
  let _1 = (outVars |> var hasindex i1 from 1 =>
      varOutput(var, retVar, i1, &varDecls, &outVarInits, &outVarCopy, &outVarAssign)
      ;separator="\n"; empty
    )
  let boxedFn = if acceptMetaModelicaGrammar() then functionBodyBoxed(fn)
  <<
  <%retType%> _<%fname%>(<%functionArguments |> var => funArgDefinition(var) ;separator=", "%>)
  {
    <%funArgs%>
    <%varDecls%>
    <%outVarInits%>
    <%if not acceptMetaModelicaGrammar() then '<%stateVar%> = get_memory_state();'%>

    <%varInits%>

    <%bodyPart%>
    
    _return:
    <%outVarCopy%>
    <%if not acceptMetaModelicaGrammar() then 'restore_memory_state(<%stateVar%>);'%>
    <%outVarAssign%>
    return<%if outVars then ' <%retVar%>' %>;
  }
  
  <% if inFunc then
  <<
  int in_<%fname%>(type_description * inArgs, type_description * outVar)
  {
    <%functionArguments |> var => '<%funArgDefinition(var)%>;' ;separator="\n"%>
    <%if outVars then '<%retType%> out;'%>
    <%functionArguments |> arg => readInVar(arg) ;separator="\n"%>
    MMC_TRY_TOP()
    <%if outVars then "out = "%>_<%fname%>(<%functionArguments |> var => funArgName(var) ;separator=", "%>);
    MMC_CATCH_TOP(return 1)
    <%if outVars then (outVars |> var hasindex i1 from 1 => writeOutVar(var, i1) ;separator="\n") else "write_noretcall(outVar);"%>
    return 0;
  }
  >>
  %>
  
  <%boxedFn%>
  >>
end functionBodyRegularFunction;

template functionBodyExternalFunction(Function fn, Boolean inFunc)
 "Generates the body for an external function (just a wrapper)."
::=
match fn
case efn as EXTERNAL_FUNCTION(__) then
  let()= System.tmpTickReset(1)
  let fname = underscorePath(name)
  let retType = if outVars then '<%fname%>_rettype' else "void"
  let &preExp = buffer "" /*BUFD*/
  let &varDecls = buffer "" /*BUFD*/
  // make sure the variable is named "out", doh!
  let retVar = if outVars then outDecl(retType, &varDecls /*BUFD*/)  
  let &outputAlloc = buffer "" /*BUFD*/
  let stateVar = if not acceptMetaModelicaGrammar() then tempDecl("state", &varDecls /*BUFD*/)
  let callPart = extFunCall(fn, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  let _ = (outVars |> var hasindex i1 from 1 =>
      varInit(var, retVar, i1, &varDecls /*BUFD*/, &outputAlloc /*BUFC*/)
    )
  let boxedFn = if acceptMetaModelicaGrammar() then functionBodyBoxed(fn)
  let fnBody = <<
  <%retType%> _<%fname%>(<%funArgs |> VARIABLE(__) => '<%expTypeArrayIf(ty)%> <%contextCref(name,contextFunction)%>' ;separator=", "%>)
  {
    <%varDecls%>
    <%if not acceptMetaModelicaGrammar() then '<%stateVar%> = get_memory_state();'%>
    <%outputAlloc%>
    <%preExp%>
    <%callPart%>
    <%if not acceptMetaModelicaGrammar() then 'restore_memory_state(<%stateVar%>);'%>
    return <%if outVars then retVar%>;
  }
  >>
  <<
  <%fnBody%>

  <% if inFunc then
  <<
  int in_<%fname%>(type_description * inArgs, type_description * outVar)
  {
    <%funArgs |> VARIABLE(__) => '<%expTypeArrayIf(ty)%> <%contextCref(name,contextFunction)%>;' ;separator="\n"%>
    <%retType%> out;
    <%funArgs |> arg as VARIABLE(__) => readInVar(arg) ;separator="\n"%>
    out = _<%fname%>(<%funArgs |> VARIABLE(__) => contextCref(name,contextFunction) ;separator=", "%>);
    <%outVars |> var as VARIABLE(__) hasindex i1 from 1 => writeOutVar(var, i1) ;separator="\n"%>
    return 0;
  }
  >> %>
  
  <%boxedFn%>
  >>
end functionBodyExternalFunction;


template functionBodyRecordConstructor(Function fn)
 "Generates the body for a record constructor."
::=
match fn
case RECORD_CONSTRUCTOR(__) then
  let()= System.tmpTickReset(1)
  let &varDecls = buffer "" /*BUFD*/
  let fname = underscorePath(name)
  let retType = '<%fname%>_rettype'
  let retVar = tempDecl(retType, &varDecls /*BUFD*/)
  let structType = 'struct <%fname%>'
  let structVar = tempDecl(structType, &varDecls /*BUFD*/)
  let boxedFn = if acceptMetaModelicaGrammar() then functionBodyBoxed(fn)
  <<
  <%retType%> _<%fname%>(<%funArgs |> VARIABLE(__) => '<%expTypeArrayIf(ty)%> <%crefStr(name)%>' ;separator=", "%>)
  {
    <%varDecls%>
    <%funArgs |> VARIABLE(__) => '<%structVar%>.<%crefStr(name)%> = <%crefStr(name)%>;' ;separator="\n"%>
    <%retVar%>.targ1 = <%structVar%>;
    return <%retVar%>;
  }

  <%boxedFn%>




  >>
end functionBodyRecordConstructor;

template functionBodyBoxed(Function fn)
 "Generates code for a boxed version of a function. Extracts the needed data
  from a function and calls functionBodyBoxedImpl"
::=
  match fn
  case FUNCTION(__) then if not isBoxedFunction(fn) then functionBodyBoxedImpl(name, functionArguments, outVars)
  case EXTERNAL_FUNCTION(__) then if not isBoxedFunction(fn) then functionBodyBoxedImpl(name, funArgs, outVars)
  case RECORD_CONSTRUCTOR(__) then boxRecordConstructor(fn) 
end functionBodyBoxed;

template functionBodyBoxedImpl(Absyn.Path name, list<Variable> funargs, list<Variable> outvars)
 "Helper template for functionBodyBoxed, does all the real work."
::=
  let() = System.tmpTickReset(1)
  let fname = underscorePath(name)
  let retType = if outvars then '<%fname%>_rettype' else "void"
  let retTypeBoxed = if outvars then '<%retType%>boxed' else "void"
  let &varDecls = buffer ""
  let retVar = if outvars then tempDecl(retTypeBoxed, &varDecls)
  let funRetVar = if outvars then tempDecl(retType, &varDecls)
  let stateVar = if not acceptMetaModelicaGrammar() then tempDecl("state", &varDecls)
  let &varBox = buffer ""
  let &varUnbox = buffer ""
  let args = (funargs |> arg => funArgUnbox(arg, &varDecls, &varBox) ;separator=", ")
  let retStr = (outvars |> var as VARIABLE(__) hasindex i1 from 1 =>
    let arg = '<%funRetVar%>.<%retType%>_<%i1%>'
    '<%retVar%>.<%retTypeBoxed%>_<%i1%> = <%funArgBox(arg, ty, &varUnbox, &varDecls)%>;'
    ;separator="\n")
  <<
  <%retTypeBoxed%> boxptr_<%fname%>(<%funargs |> var => funArgBoxedDefinition(var) ;separator=", "%>)
  {
    <%varDecls%>
    <%if not acceptMetaModelicaGrammar() then '<%stateVar%> = get_memory_state();'%>
    <%varBox%>
    <%if outvars then '<%funRetVar%> = '%>_<%fname%>(<%args%>);
    <%varUnbox%>
    <%retStr%>
    <%if not acceptMetaModelicaGrammar() then 'restore_memory_state(<%stateVar%>);'%>
    return <%retVar%>;
  }
  >>
end functionBodyBoxedImpl;

template boxRecordConstructor(Function fn)
::=
match fn
case RECORD_CONSTRUCTOR(__) then
  let() = System.tmpTickReset(1)
  let fname = underscorePath(name)
  let funArgsStr = (funArgs |> var as VARIABLE(__) => contextCref(name,contextFunction) ;separator=", ")
  let funArgCount = incrementInt(listLength(funArgs), 1)
  <<
  modelica_metatype boxptr_<%fname%>(<%funArgs |> var => funArgBoxedDefinition(var) ;separator=", "%>)
  {
    return mmc_mk_box<%funArgCount%>(3, &<%fname%>__desc, <%funArgsStr%>);
  }
  >>
end boxRecordConstructor;

template funArgUnbox(Variable var, Text &varDecls, Text &varBox)
::=
match var
case VARIABLE(__) then
  let varName = contextCref(name,contextFunction)
  unboxVariable(varName, ty, &varBox, &varDecls)
case FUNCTION_PTR(__) then // Function pointers don't need to be boxed.
  name 
end funArgUnbox;

template unboxVariable(String varName, ExpType varType, Text &preExp, Text &varDecls)
::=
match varType
case ET_STRING(__) case ET_METATYPE(__) case ET_BOXED(__) then varName
case ET_COMPLEX(complexClassType = RECORD(__)) then
  unboxRecord(varName, varType, &preExp, &varDecls)
else
  let shortType = mmcExpTypeShort(varType)
  let ty = 'modelica_<%shortType%>'
  let tmpVar = tempDecl(ty, &varDecls)
  let &preExp += '<%tmpVar%> = mmc_unbox_<%shortType%>(<%varName%>);<%\n%>'
  tmpVar
end unboxVariable;

template unboxRecord(String recordVar, ExpType ty, Text &preExp, Text &varDecls)
::=
match ty
case ET_COMPLEX(complexClassType = RECORD(path = path), varLst = vars) then
  let tmpVar = tempDecl('struct <%underscorePath(path)%>', &varDecls)
  let &preExp += (vars |> COMPLEX_VAR(name = compname) hasindex offset from 2 =>
    let varType = mmcExpTypeShort(tp)
    let untagTmp = tempDecl('modelica_metatype', &varDecls)
    //let offsetStr = incrementInt(i1, 1)
    let &unboxBuf = buffer ""
    let unboxStr = unboxVariable(untagTmp, tp, &unboxBuf, &varDecls)
    <<
    <%untagTmp%> = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(<%recordVar%>), <%offset%>)));
    <%unboxBuf%>
    <%tmpVar%>.<%compname%> = <%unboxStr%>;
    >>
    ;separator="\n")
  tmpVar
end unboxRecord; 

template funArgBox(String varName, ExpType ty, Text &varUnbox, Text &varDecls)
 "Generates code to box a variable."
::=
  let constructorType = mmcConstructorType(ty)
  if constructorType then
    let constructor = mmcConstructor(ty, varName, &varUnbox, &varDecls)
    let tmpVar = tempDecl(constructorType, &varDecls)
    let &varUnbox += '<%tmpVar%> = <%constructor%>;<%\n%>'
    tmpVar
  else // Some types don't need to be boxed, since they're already boxed.
    varName
end funArgBox;

template mmcConstructorType(ExpType type)
::=
  match type
  case ET_INT(__)
  case ET_BOOL(__)
  case ET_REAL(__)
  case ET_ENUMERATION(__)
  case ET_ARRAY(__)
  case ET_COMPLEX(__) then 'modelica_metatype'
end mmcConstructorType;

template mmcConstructor(ExpType type, String varName, Text &preExp, Text &varDecls)
::=
  match type
  case ET_INT(__) then 'mmc_mk_icon(<%varName%>)'
  case ET_BOOL(__) then 'mmc_mk_icon(<%varName%>)'
  case ET_REAL(__) then 'mmc_mk_rcon(<%varName%>)'
  case ET_STRING(__) then 'mmc_mk_string(<%varName%>)'
  case ET_ENUMERATION(__) then 'mmc_mk_icon(<%varName%>)'
  case ET_ARRAY(__) then 'mmc_mk_acon(<%varName%>)'
  case ET_COMPLEX(complexClassType = RECORD(path = path), varLst = vars) then
    let varCount = incrementInt(listLength(vars), 1)
    //let varsStr = (vars |> var as COMPLEX_VAR(__) => '<%varName%>.<%name%>' ;separator=", ")
    let varsStr = (vars |> var as COMPLEX_VAR(__) =>
      let varname = '<%varName%>.<%name%>'
      funArgBox(varname, tp, &preExp, &varDecls) ;separator=", ")
    'mmc_mk_box<%varCount%>(3, &<%underscorePath(path)%>__desc, <%varsStr%>)'
  case ET_COMPLEX(__) then 'mmc_mk_box(<%varName%>)'
end mmcConstructor;

template readInVar(Variable var)
 "Generates code for reading a variable from inArgs."
::=
  match var
  case VARIABLE(name=cr, ty=ET_COMPLEX(complexClassType=RECORD(__))) then
    <<
    if (read_modelica_record(&inArgs, <%readInVarRecordMembers(ty, contextCref(cr,contextFunction))%>)) return 1;
    >>
  case VARIABLE(name=cr, ty=ET_STRING(__)) then
    <<
    if (read_<%expTypeArrayIf(ty)%>(&inArgs, <%if not acceptMetaModelicaGrammar() then "(char**)"%> &<%contextCref(name,contextFunction)%>)) return 1;
    >>
  case VARIABLE(__) then
    <<
    if (read_<%expTypeArrayIf(ty)%>(&inArgs, &<%contextCref(name,contextFunction)%>)) return 1;
    >>
end readInVar;


template readInVarRecordMembers(ExpType type, String prefix)
 "Helper to readInVar."
::=
match type
case ET_COMPLEX(varLst=vl) then
  (vl |> subvar as COMPLEX_VAR(__) =>
    match tp case ET_COMPLEX(__) then
      let newPrefix = '<%prefix%>.<%subvar.name%>'
      readInVarRecordMembers(tp, newPrefix)
    else
      '&(<%prefix%>.<%subvar.name%>)'
  ;separator=", ")
end readInVarRecordMembers;


template writeOutVar(Variable var, Integer index)
 "Generates code for writing a variable to outVar."

::=
  match var
  case VARIABLE(ty=ET_COMPLEX(complexClassType=RECORD(__))) then
    <<
    write_modelica_record(outVar, <%writeOutVarRecordMembers(ty, index, "")%>);
    >>
  case VARIABLE(__) then

    <<
    write_<%varType(var)%>(outVar, &out.targ<%index%>);
    >>
end writeOutVar;


template writeOutVarRecordMembers(ExpType type, Integer index, String prefix)
 "Helper to writeOutVar."
::=
match type
case ET_COMPLEX(varLst=vl, name=n) then
  let basename = underscorePath(n)
  let args = (vl |> subvar as COMPLEX_VAR(__) =>
      match tp case ET_COMPLEX(__) then
        let newPrefix = '<%prefix%>.<%subvar.name%>'
        '<%expTypeRW(tp)%>, <%writeOutVarRecordMembers(tp, index, newPrefix)%>'
      else
        '<%expTypeRW(tp)%>, &(out.targ<%index%><%prefix%>.<%subvar.name%>)'
    ;separator=", ")
  <<
  &<%basename%>__desc<%if args then ', <%args%>'%>, TYPE_DESC_NONE
  >>
end writeOutVarRecordMembers;


template varInit(Variable var, String outStruct, Integer i, Text &varDecls /*BUFP*/, Text &varInits /*BUFP*/)
 "Generates code to initialize variables.
  Does not return anything: just appends declarations to buffers."
::=
match var
case var as VARIABLE(__) then
  let &varDecls += if not outStruct then '<%varType(var)%> <%contextCref(var.name,contextFunction)%>;<%\n%>' //else ""
  let varName = if outStruct then '<%outStruct%>.targ<%i%>' else '<%contextCref(var.name,contextFunction)%>'
  let instDimsInit = (instDims |> exp =>
      daeExp(exp, contextFunction, &varInits /*BUFC*/, &varDecls /*BUFD*/)
    ;separator=", ") 
  if instDims then
    let &varInits += 'alloc_<%expTypeShort(var.ty)%>_array(&<%varName%>, <%listLength(instDims)%>, <%instDimsInit%>);<%\n%>'
    let defaultValue = varDefaultValue(var, outStruct, i, varName, &varDecls, &varInits)
    let &varInits += defaultValue
    " "
  else
    (match var.value
    case SOME(exp) then
      let defaultValue = '<%contextCref(var.name,contextFunction)%> = <%daeExp(exp, contextFunction, &varInits  /*BUFC*/, &varDecls /*BUFD*/)%>;<%\n%>'
      let &varInits += defaultValue
      " "
    else
      "")
case var as FUNCTION_PTR(__) then
  let &ignore = buffer ""
  let &varDecls += functionArg(var,&ignore)
  ""
else let &varDecls += '#error Unknown local variable type<%\n%>' ""
end varInit;

template varDefaultValue(Variable var, String outStruct, Integer i, String lhsVarName,  Text &varDecls /*BUFP*/, Text &varInits /*BUFP*/)
::=
match var
case var as VARIABLE(__) then
  match value
  case SOME(CREF(componentRef = cr)) then
    'copy_<%expTypeShort(var.ty)%>_array_data(&<%contextCref(cr,contextFunction)%>, &<%outStruct%>.targ<%i%>);<%\n%>'
  case SOME(arr as ARRAY(__)) then
    let arrayExp = '<%daeExp(arr, contextFunction, &varInits /*BUFC*/, &varDecls /*BUFD*/)%>'
    <<
    copy_<%expTypeShort(var.ty)%>_array_data(&<%arrayExp%>, &<%lhsVarName%>);<%\n%>
    >>
end varDefaultValue;

template functionArg(Variable var, Text &varInit)
"Shared code for function arguments that are part of the function variables and valueblocks.
Valueblocks need to declare a reference to the function while input variables
need to initialize."
::=
match var
case var as FUNCTION_PTR(__) then
  let typelist = (args |> arg => mmcVarType(arg) ;separator=", ")
  let rettype = '<%name%>_rettype'
  match tys
    case {} then
      let &varInit += '_<%name%> = (void(*)(<%typelist%>)) <%name%><%\n%>;'
      'void(*_<%name%>)(<%typelist%>);<%\n%>'
    else
      let &varInit += '_<%name%> = (<%rettype%>(*)(<%typelist%>)) <%name%>;<%\n%>'
      <<
      <% tys |> arg hasindex i1 from 1 => '#define <%rettype%>_<%i1%> targ<%i1%>' ; separator="\n" %>
      typedef struct <%rettype%>_s
      {
        <% tys |> ty hasindex i1 from 1 => 'modelica_<%mmcExpTypeShort(ty)%> targ<%i1%>;' ; separator="\n" %> 
      } <%rettype%>;
      <%rettype%>(*_<%name%>)(<%typelist%>);<%\n%>
      >>
  end match
end functionArg;
  
template varOutput(Variable var, String dest, Integer ix, Text &varDecls,
          Text &varInits, Text &varCopy, Text &varAssign)
 "Generates code to copy result value from a function to dest."
::=
match var
/* The storage size of arrays is known at call time, so they can be allocated
 * before set_memory_state. Strings are not known, so we copy them, etc...
 */
case var as VARIABLE(ty = ET_STRING(__)) then
    if not acceptMetaModelicaGrammar() then
      // We need to strdup() all strings, then allocate them on the memory pool again, then free the temporary string
      let strVar = tempDecl("modelica_string_t", &varDecls)
      let &varCopy += '<%strVar%> = strdup(<%contextCref(var.name,contextFunction)%>);<%\n%>'
      let &varAssign +=
        <<
        <%dest%>.targ<%ix%> = init_modelica_string(<%strVar%>);
        free(<%strVar%>);<%\n%>
        >>
      ""
    else
      let &varAssign += '<%dest%>.targ<%ix%> = <%contextCref(var.name,contextFunction)%>;<%\n%>'
      ""
case var as VARIABLE(__) then
  let instDimsInit = (instDims |> exp =>
      daeExp(exp, contextFunction, &varInits /*BUFC*/, &varDecls /*BUFD*/)
    ;separator=", ")
  if instDims then
    let &varInits += 'alloc_<%expTypeShort(var.ty)%>_array(&<%dest%>.targ<%ix%>, <%listLength(instDims)%>, <%instDimsInit%>);<%\n%>'
    let &varAssign += 'copy_<%expTypeShort(var.ty)%>_array_data(&<%contextCref(var.name,contextFunction)%>, &<%dest%>.targ<%ix%>);<%\n%>'
    ""
  else
    let &varInits += initRecordMembers(var)
    let &varAssign += '<%dest%>.targ<%ix%> = <%contextCref(var.name,contextFunction)%>;<%\n%>'
    ""
case var as FUNCTION_PTR(__) then
    let &varAssign += '<%dest%>.targ<%ix%> = (modelica_fnptr) _<%var.name%>;<%\n%>'
    ""
end varOutput;

template initRecordMembers(Variable var)
::=
match var
case VARIABLE(ty = ET_COMPLEX(complexClassType = RECORD(__))) then
  let varName = contextCref(name,contextFunction)
  (ty.varLst |> v => recordMemberInit(v, varName) ;separator="\n")
end initRecordMembers;

template recordMemberInit(ExpVar v, Text varName)
::=
match v
case COMPLEX_VAR(tp = ET_ARRAY(__)) then 
  let arrayType = expType(tp, true) 
  let dims = (tp.arrayDimensions |> dim => dimension(dim) ;separator=", ")
  'alloc_<%arrayType%>(&<%varName%>.<%name%>, <%listLength(tp.arrayDimensions)%>, <%dims%>);'
end recordMemberInit;

template extVarName(ComponentRef cr)
::= '<%contextCref(cr,contextFunction)%>_ext'
end extVarName;

template extFunCall(Function fun, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Generates the call to an external function."
::=
match fun
case EXTERNAL_FUNCTION(__) then
  match language
  case "C" then extFunCallC(fun, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case "FORTRAN 77" then extFunCallF77(fun, &preExp /*BUFC*/, &varDecls /*BUFD*/)
end extFunCall;

template extFunCallC(Function fun, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Generates the call to an external C function."
::=
match fun
case EXTERNAL_FUNCTION(__) then
  let args = (extArgs |> arg =>
      extArg(arg, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    ;separator=", ")
  let returnAssign = match extReturn case SIMEXTARG(cref=c) then
      '<%extVarName(c)%> = '
    else
      ""
  <<
  <%extArgs |> arg => extFunCallVardecl(arg, &varDecls /*BUFD*/) ;separator="\n"%>
  <%match extReturn case SIMEXTARG(__) then extFunCallVardecl(extReturn, &varDecls /*BUFD*/)%>
  <%returnAssign%><%extName%>(<%args%>);
  <%extArgs |> arg => extFunCallVarcopy(arg) ;separator="\n"%>
  <%match extReturn case SIMEXTARG(__) then extFunCallVarcopy(extReturn)%>
  >>
end extFunCallC;

template extFunCallF77(Function fun, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Generates the call to an external Fortran 77 function."
::=
match fun
case EXTERNAL_FUNCTION(__) then
  let args = (extArgs |> arg => extArgF77(arg, &preExp, &varDecls) ;separator=", ")
  let returnAssign = match extReturn case SIMEXTARG(cref=c) then
      '<%extVarName(c)%> = '
    else
      ""
  <<
  <%extArgs |> arg => extFunCallVardeclF77(arg, &varDecls) ;separator="\n"%>
  <%match extReturn case SIMEXTARG(__) then extFunCallVardeclF77(extReturn, &varDecls /*BUFD*/)%>
  <%biVars |> arg => extFunCallBiVarF77(arg, &preExp, &varDecls) ;separator="\n"%>
  <%returnAssign%><%extName%>_(<%args%>);
  <%extArgs |> arg => extFunCallVarcopyF77(arg) ;separator="\n"%>
  <%match extReturn case SIMEXTARG(__) then extFunCallVarcopyF77(extReturn)%>
  >>

end extFunCallF77;

template extFunCallVardecl(SimExtArg arg, Text &varDecls /*BUFP*/)
 "Helper to extFunCall."
::=
  match arg
  case SIMEXTARG(isInput=true, isArray=false, type_=ty, cref=c) then
    match ty case ET_STRING(__) then
      ""
    else
      let &varDecls += '<%extType(ty)%> <%contextCref(c,contextFunction)%>_ext;<%\n%>'
      <<
      <%contextCref(c,contextFunction)%>_ext = (<%extType(ty)%>)<%contextCref(c,contextFunction)%>;
      >>
  case SIMEXTARG(outputIndex=oi, isArray=false, type_=ty, cref=c) then
    match oi case 0 then
      ""
    else
      let &varDecls += '<%extType(ty)%> <%extVarName(c)%>;<%\n%>'
      ""
end extFunCallVardecl;

template extFunCallVardeclF77(SimExtArg arg, Text &varDecls)
::=
  match arg
  case SIMEXTARG(isInput = true, isArray = true, type_ = ty, cref = c) then
    let &varDecls += '<%expTypeArrayIf(ty)%> <%extVarName(c)%>;<%\n%>'
    'convert_alloc_<%expTypeArray(ty)%>_to_f77(&<%contextCref(c,contextFunction)%>, &<%extVarName(c)%>);'
  case SIMEXTARG(outputIndex = oi, isArray = ia, type_= ty, cref = c) then
    match oi case 0 then "" else
      match ia
        case false then
          let &varDecls += '<%extType(ty)%> <%extVarName(c)%>;<%\n%>'
          ""
        else
          let &varDecls += '<%expTypeArrayIf(ty)%> <%extVarName(c)%>;<%\n%>'
          'convert_alloc_<%expTypeArray(ty)%>_to_f77(&out.targ<%oi%>, &<%extVarName(c)%>);'
  case SIMEXTARG(type_ = ty, cref = c) then
    let &varDecls += '<%extType(ty)%> <%extVarName(c)%>;<%\n%>'
    ""
end extFunCallVardeclF77;

template extFunCallBiVarF77(Variable var, Text &preExp, Text &varDecls)
::=
  match var
  case var as VARIABLE(__) then
    let var_name = contextCref(name,contextFunction)
    let &varDecls += '<%varType(var)%> <%var_name%>;<%\n%>'
    let &varDecls += '<%varType(var)%> <%extVarName(name)%>;<%\n%>'
    let defaultValue = match value 
      case SOME(v) then
        '<%var_name%> = <%daeExp(v, contextFunction, &preExp /*BUFC*/, &varDecls /*BUFD*/)%>;<%\n%>'
      else ""
    let &preExp += defaultValue
    let instDimsInit = (instDims |> exp =>
        daeExp(exp, contextFunction, &preExp /*BUFC*/, &varDecls /*BUFD*/) ;separator=", ")
    if instDims then
      let type = expTypeArray(var.ty)
      let &preExp += 'alloc_<%type%>(&<%var_name%>, <%listLength(instDims)%>, <%instDimsInit%>);<%\n%>'
      let &preExp += 'convert_alloc_<%type%>_to_f77(&<%var_name%>, &<%extVarName(name)%>);<%\n%>'
      ""
    else
      ""
end extFunCallBiVarF77;

template extFunCallVarcopy(SimExtArg arg)
 "Helper to extFunCall."
::=
match arg
case SIMEXTARG(outputIndex=oi, isArray=false, type_=ty, cref=c) then
  match oi case 0 then
    ""
  else
    let cr = '<%contextCref(c,contextFunction)%>_ext'
    <<
    out.targ<%oi%> = (<%expTypeModelica(ty)%>)<%
      if acceptMetaModelicaGrammar() then
        (match ty
          case ET_STRING(__) then 'mmc_mk_scon(<%cr%>)'
          else cr)
      else cr %>;
    >>
end extFunCallVarcopy;

template extFunCallVarcopyF77(SimExtArg arg)
 "Generates code to copy results from output variables into the out struct.
  Helper to extFunCallF77."
::=
match arg
case SIMEXTARG(outputIndex=oi, isArray=ai, type_=ty, cref=c) then
  match oi case 0 then
    ""
  else
    let outarg = 'out.targ<%oi%>'
    let ext_name = '<%contextCref(c,contextFunction)%>_ext'
    match ai 
    case false then 
      '<%outarg%> = (<%expTypeModelica(ty)%>)<%ext_name%>;<%\n%>'
    case true then
      'convert_alloc_<%expTypeArray(ty)%>_from_f77(&<%ext_name%>, &<%outarg%>);'
end extFunCallVarcopyF77;

template extArg(SimExtArg extArg, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Helper to extFunCall."
::=
  match extArg
  case SIMEXTARG(cref=c, outputIndex=oi, isArray=true, type_=t) then
    let name = if oi then 'out.targ<%oi%>' else contextCref(c,contextFunction)
    let shortTypeStr = expTypeShort(t)
    'data_of_<%shortTypeStr%>_array(&(<%name%>))'
  case SIMEXTARG(cref=c, isInput=ii, outputIndex=0, type_=t) then
    let cr = '<%contextCref(c,contextFunction)%>'
    if acceptMetaModelicaGrammar() then
      (match t case ET_STRING(__) then 'MMC_STRINGDATA(<%cr%>)' else '<%cr%>_ext')
    else
      '<%cr%><%match t case ET_STRING(__) then "" else "_ext"%>'
  case SIMEXTARG(cref=c, isInput=ii, outputIndex=oi, type_=t) then
    '&<%contextCref(c,contextFunction)%>_ext'
  case SIMEXTARGEXP(__) then
    daeExp(exp, contextFunction, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case SIMEXTARGSIZE(cref=c) then
    let typeStr = expTypeShort(type_)
    let name = if outputIndex then 'out.targ<%outputIndex%>' else contextCref(c,contextFunction)
    let dim = daeExp(exp, contextFunction, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    'size_of_dimension_<%typeStr%>_array(<%name%>, <%dim%>)'
end extArg;

template extArgF77(SimExtArg extArg, Text &preExp, Text &varDecls)
::=
  match extArg
  case SIMEXTARG(cref=c, isArray=true, type_=t) then
    // Arrays are converted to fortran format that are stored in _ext-variables.
    'data_of_<%expTypeShort(t)%>_array(&(<%extVarName(c)%>))' 
  case SIMEXTARG(cref=c, outputIndex=oi, type_=ET_INT()) then
    // Always prefix fortran arguments with &.
    let suffix = if oi then "_ext"
    '(int*) &<%contextCref(c,contextFunction)%><%suffix%>'
  case SIMEXTARG(cref=c, outputIndex=oi, type_=t) then
    // Always prefix fortran arguments with &.
    let suffix = if oi then "_ext"
    '&<%contextCref(c,contextFunction)%><%suffix%>'
  case SIMEXTARGEXP(__) then
    let texp = daeExp(exp, contextFunction, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let tvar = tempDecl(expTypeFromExpFlag(exp,8),&varDecls)
    let &preExp += '<%tvar%> = <%texp%>;<%\n%>'
    '&<%tvar%>'
  case SIMEXTARGSIZE(cref=c) then
    // Fortran functions only takes references to variables, so we must store
    // the result from size_of_dimension_<type>_array in a temporary variable.
    let sizeVarName = tempSizeVarName(c, exp)
    let sizeVar = tempDecl("int", &varDecls)
    let dim = daeExp(exp, contextFunction, &preExp, &varDecls)
    let size_call = 'size_of_dimension_<%expTypeShort(type_)%>_array'
    let &preExp += '<%sizeVar%> = <%size_call%>(<%contextCref(c,contextFunction)%>, <%dim%>);<%\n%>'
    '&<%sizeVar%>'
end extArgF77;

template tempSizeVarName(ComponentRef c, DAE.Exp indices)

::=
  match indices
  case ICONST(__) then '<%contextCref(c,contextFunction)%>_size_<%integer%>'
  else "tempSizeVarName:UNHANDLED_EXPRESSION"
end tempSizeVarName;

template funStatement(Statement stmt, Text &varDecls /*BUFP*/)
 "Generates function statements."
::=
  match stmt
  case ALGORITHM(__) then
    (statementLst |> stmt =>
      algStatement(stmt, contextFunction, &varDecls /*BUFD*/)
    ;separator="\n") 
  else
    "NOT IMPLEMENTED FUN STATEMENT"
end funStatement;

template statementInfoString(DAE.Statement stmt)
::=
  match stmt
  case STMT_ASSIGN(__)
  case STMT_ASSIGN_ARR(__)
  case STMT_TUPLE_ASSIGN(__)
  case STMT_IF(__)
  case STMT_FOR(__)
  case STMT_WHILE(__)
  case STMT_ASSERT(__)
  case STMT_TERMINATE(__)
  case STMT_WHEN(__)
  case STMT_BREAK(__)
  case STMT_FAILURE(__)
  case STMT_TRY(__)
  case STMT_CATCH(__)
  case STMT_THROW(__)
  case STMT_RETURN(__)
  case STMT_NORETCALL(__)
  case STMT_REINIT(__)
  then (match source case s as SOURCE(__) then infoStr(s.info))
end statementInfoString;

template algStatement(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/)
 "Generates an algorithm statement."
::=
  let res = match stmt
  case s as STMT_ASSIGN(exp1=PATTERN(__)) then algStmtAssignPattern(s, context, &varDecls /*BUFD*/)
  case s as STMT_ASSIGN(__)         then algStmtAssign(s, context, &varDecls /*BUFD*/)
  case s as STMT_ASSIGN_ARR(__)     then algStmtAssignArr(s, context, &varDecls /*BUFD*/)
  case s as STMT_TUPLE_ASSIGN(__)   then algStmtTupleAssign(s, context, &varDecls /*BUFD*/)
  case s as STMT_IF(__)             then algStmtIf(s, context, &varDecls /*BUFD*/)
  case s as STMT_FOR(__)            then algStmtFor(s, context, &varDecls /*BUFD*/)
  case s as STMT_WHILE(__)          then algStmtWhile(s, context, &varDecls /*BUFD*/)
  case s as STMT_ASSERT(__)         then algStmtAssert(s, context, &varDecls /*BUFD*/)
  case s as STMT_TERMINATE(__)      then algStmtTerminate(s, context, &varDecls /*BUFD*/)
  case s as STMT_WHEN(__)           then algStmtWhen(s, context, &varDecls /*BUFD*/)
  case s as STMT_BREAK(__)          then 'break;<%\n%>'
  case s as STMT_FAILURE(__)        then algStmtFailure(s, context, &varDecls /*BUFD*/)
  case s as STMT_TRY(__)            then algStmtTry(s, context, &varDecls /*BUFD*/)
  case s as STMT_CATCH(__)          then algStmtCatch(s, context, &varDecls /*BUFD*/)
  case s as STMT_THROW(__)          then 'MMC_THROW();<%\n%>'
  case s as STMT_RETURN(__)         then 'goto _return;<%\n%>'
  case s as STMT_NORETCALL(__)      then algStmtNoretcall(s, context, &varDecls /*BUFD*/)
  case s as STMT_REINIT(__)     then algStmtReinit(s, context, &varDecls /*BUFD*/)
  else "#error NOT_IMPLEMENTED_ALG_STATEMENT"
  <<
  /*#modelicaLine <%statementInfoString(stmt)%>*/
  <%res%>
  /*#endModelicaLine*/
  >>
end algStatement;


template algStmtAssign(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/)
 "Generates an assigment algorithm statement."
::=
  match stmt
  case STMT_ASSIGN(exp1=CREF(componentRef=WILD(__)), exp=e) then
    let &preExp = buffer "" /*BUFD*/
    let expPart = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    <<
    <%preExp%>
    >>
  case STMT_ASSIGN(exp1=CREF(ty = ET_FUNCTION_REFERENCE_VAR(__)))
  case STMT_ASSIGN(exp1=CREF(ty = ET_FUNCTION_REFERENCE_FUNC(__))) then
    let &preExp = buffer "" /*BUFD*/
    let varPart = scalarLhsCref(exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    <<
    <%preExp%>
    <%varPart%> = (modelica_fnptr) <%expPart%>;
    >>
  case STMT_ASSIGN(exp1=CREF(__)) then
    let &preExp = buffer "" /*BUFD*/
    let varPart = scalarLhsCref(exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    <<
    <%preExp%>
    <%varPart%> = <%expPart%>;
    >>
  case STMT_ASSIGN(exp1=exp1 as ASUB(__),exp=val) then
    (match expTypeFromExpShort(exp)
      case "metatype" then
        // MetaModelica Array
        (match exp case ASUB(exp=arr, sub={idx}) then
        let &preExp = buffer ""
        let arr1 = daeExp(arr, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
        let idx1 = daeExp(idx, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
        let val1 = daeExp(val, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
        <<
        <%preExp%>
        arrayUpdate(<%arr1%>,<%idx1%>,<%val1%>);
        >>)
        // Modelica Array
      else
        let &preExp = buffer "" /*BUFD*/
        let varPart = daeExpAsub(exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
        let expPart = daeExp(val, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
        <<
        <%preExp%>
        <%varPart%> = <%expPart%>;
        >>
    )
  case STMT_ASSIGN(__) then
    let &preExp = buffer "" /*BUFD*/
    let expPart1 = daeExp(exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let expPart2 = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    <<
    <%preExp%>
    <%expPart1%> = <%expPart2%>;
    >>
end algStmtAssign;


template algStmtAssignArr(DAE.Statement stmt, Context context,
                 Text &varDecls /*BUFP*/)
 "Generates an array assigment algorithm statement."
::=
match stmt
case STMT_ASSIGN_ARR(exp=e, componentRef=cr, type_=t) then
  let &preExp = buffer "" /*BUFD*/
  let expPart = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  let ispec = indexSpecFromCref(cr, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)  
  if ispec then
    <<
    <%preExp%>
    <%indexedAssign(t, expPart, cr, ispec, context, &varDecls)%>
    >>
  else
    <<
    <%preExp%>
    <%copyArrayData(t, expPart, cr, context)%>
    >>
end algStmtAssignArr;

template indexedAssign(DAE.ExpType ty, String exp, DAE.ComponentRef cr, 
  String ispec, Context context, Text &varDecls)
::=
  let type = expTypeArray(ty)
  let cref = contextArrayCref(cr, context)
  match context
  case FUNCTION_CONTEXT(__) then
    'indexed_assign_<%type%>(&<%exp%>, &<%cref%>, &<%ispec%>);'
  else
    let tmp = tempDecl("real_array", &varDecls)
    <<
    indexed_assign_<%type%>(&<%exp%>, &<%tmp%>, &<%ispec%>);
    copy_<%type%>_data_mem(&<%tmp%>, &<%cref%>);
    >>
end indexedAssign;

template copyArrayData(DAE.ExpType ty, String exp, DAE.ComponentRef cr,
  Context context)
::=
  let type = expTypeArray(ty)
  let cref = contextArrayCref(cr, context)
  match context
  case FUNCTION_CONTEXT(__) then
    'copy_<%type%>_data(&<%exp%>, &<%cref%>);'
  else
    'copy_<%type%>_data_mem(&<%exp%>, &<%cref%>);'
end copyArrayData;
    
template algStmtTupleAssign(DAE.Statement stmt, Context context,
                   Text &varDecls /*BUFP*/)
 "Generates a tuple assigment algorithm statement."
::=
match stmt
case STMT_TUPLE_ASSIGN(exp=CALL(__)) then
  let &preExp = buffer "" /*BUFD*/
  let retStruct = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  <<
  <%preExp%>
  <%expExpLst |> cr hasindex i1 from 1 =>
    let rhsStr = '<%retStruct%>.targ<%i1%>'
    writeLhsCref(cr, rhsStr, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  ;separator="\n"%>
  >>
case STMT_TUPLE_ASSIGN(exp=MATCHEXPRESSION(__)) then
  let &preExp = buffer "" /*BUFD*/
  let prefix = 'tmp<%System.tmpTick()%>'
  let _ = daeExpMatch2(exp, expExpLst, prefix, context, &preExp, &varDecls)
  <<
  <%expExpLst |> cr hasindex i1 from 1 =>
    let rhsStr = '<%prefix%>_targ<%i1%>'
    let &varDecls += '<%expTypeFromExpModelica(cr)%> <%rhsStr%>;<%\n%>'
    ""
  ;separator="\n";empty%>
  <%preExp%>
  <%expExpLst |> cr hasindex i1 from 1 =>
    let rhsStr = '<%prefix%>_targ<%i1%>'
    writeLhsCref(cr, rhsStr, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  ;separator="\n"%>
  >>
else
  <<
  #error "algStmtTupleAssign failed"
  >>
end algStmtTupleAssign;

template writeLhsCref(Exp exp, String rhsStr, Context context, Text &preExp /*BUFP*/,
              Text &varDecls /*BUFP*/)
 "Generates code for writing a returnStructur to var."
::=
match exp
case ecr as CREF(componentRef=WILD(__)) then
  ''
case CREF(ty= t as DAE.ET_ARRAY(__)) then
  let lhsStr = scalarLhsCref(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  match context
  case SIMULATION(__)
  case SIMULATION2(__) then
    <<
    copy_<%expTypeShort(t)%>_array_data_mem(&<%rhsStr%>, &<%lhsStr%>);
    >>
  else
    '<%lhsStr%> = <%rhsStr%>;'
case UNARY(exp = e as CREF(ty= t as DAE.ET_ARRAY(__))) then
  let lhsStr = scalarLhsCref(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  match context
  case SIMULATION(__)
  case SIMULATION2(__) then
    <<
    usub_<%expTypeShort(t)%>_array(&<%rhsStr%>);<%\n%>
    copy_<%expTypeShort(t)%>_array_data_mem(&<%rhsStr%>, &<%lhsStr%>);
    >>
  else
    '<%lhsStr%> = -<%rhsStr%>;'
case CREF(__) then
  let lhsStr = scalarLhsCref(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  <<
  <%lhsStr%> = <%rhsStr%>;
  >>   
case UNARY(exp = e as CREF(__)) then
  let lhsStr = scalarLhsCref(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  <<
  <%lhsStr%> = -<%rhsStr%>;
  >>   
end writeLhsCref;

template algStmtIf(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/)
 "Generates an if algorithm statement."
::=
match stmt
case STMT_IF(__) then
  let &preExp = buffer "" /*BUFD*/
  let condExp = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  <<
  <%preExp%>
  if (<%condExp%>) {
    <%statementLst |> stmt => algStatement(stmt, context, &varDecls /*BUFD*/) ;separator="\n"%>
  }
  <%elseExpr(else_, context, &varDecls /*BUFD*/)%>
  >>
end algStmtIf;


template algStmtFor(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/)
 "Generates a for algorithm statement."
::=
  match stmt
  case s as STMT_FOR(range=rng as RANGE(__)) then
    algStmtForRange(s, context, &varDecls /*BUFD*/)
  case s as STMT_FOR(__) then
    algStmtForGeneric(s, context, &varDecls /*BUFD*/)
end algStmtFor;


template algStmtForRange(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/)
 "Generates a for algorithm statement where range is RANGE."
::=
match stmt
case STMT_FOR(range=rng as RANGE(__)) then
  let identType = expType(type_, iterIsArray)
  let identTypeShort = expTypeShort(type_)
  let stmtStr = (statementLst |> stmt => algStatement(stmt, context, &varDecls)
                 ;separator="\n")
  algStmtForRange_impl(rng, iter, identType, identTypeShort, stmtStr, context, &varDecls)
end algStmtForRange;

template algStmtForRange_impl(Exp range, Ident iterator, String type, String shortType, Text body, Context context, Text &varDecls)
 "The implementation of algStmtForRange, which is also used by daeExpReduction."
::=
match range
case RANGE(__) then
  let iterName = contextIteratorName(iterator, context)
  let stateVar = if not acceptMetaModelicaGrammar() then tempDecl("state", &varDecls)
  let startVar = tempDecl(type, &varDecls)
  let stepVar = tempDecl(type, &varDecls)
  let stopVar = tempDecl(type, &varDecls)
  let &preExp = buffer ""
  let startValue = daeExp(exp, context, &preExp, &varDecls)
  let stepValue = match expOption case SOME(eo) then
      daeExp(eo, context, &preExp, &varDecls)
    else
      "(1)"
  let stopValue = daeExp(range, context, &preExp, &varDecls)
  <<
  <%preExp%>
  <%startVar%> = <%startValue%>; <%stepVar%> = <%stepValue%>; <%stopVar%> = <%stopValue%>; 
  {
    for(<%type%> <%iterName%> = <%startValue%>; in_range_<%shortType%>(<%iterName%>, <%startVar%>, <%stopVar%>); <%iterName%> += <%stepVar%>) { 
      <%if not acceptMetaModelicaGrammar() then '<%stateVar%> = get_memory_state();'%>
      <%body%>
      <%if not acceptMetaModelicaGrammar() then 'restore_memory_state(<%stateVar%>);'%>
    }
  }
  >>
end algStmtForRange_impl;

template algStmtForGeneric(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/)
 "Generates a for algorithm statement where range is not RANGE."
::=
match stmt
case STMT_FOR(__) then
  let iterType = expType(type_, iterIsArray)
  let arrayType = expTypeArray(type_)
  let stmtStr = (statementLst |> stmt => 
    algStatement(stmt, context, &varDecls) ;separator="\n")
  algStmtForGeneric_impl(range, iter, iterType, arrayType, iterIsArray, stmtStr, 
    context, &varDecls)
end algStmtForGeneric;

template algStmtForGeneric_impl(Exp exp, Ident iterator, String type, 
  String arrayType, Boolean iterIsArray, Text &body, Context context, Text &varDecls)
 "The implementation of algStmtForGeneric, which is also used by daeExpReduction."
::=
  let iterName = contextIteratorName(iterator, context)
  let stateVar = if not acceptMetaModelicaGrammar() then tempDecl("state", &varDecls)
  let tvar = tempDecl("int", &varDecls)
  let ivar = tempDecl(type, &varDecls)
  let &preExp = buffer ""
  let evar = daeExp(exp, context, &preExp, &varDecls)
  let stmtStuff = if iterIsArray then
      'simple_index_alloc_<%type%>1(&<%evar%>, <%tvar%>, &<%ivar%>);'
    else
      '<%iterName%> = *(<%arrayType%>_element_addr1(&<%evar%>, 1, <%tvar%>));'
  <<
  <%preExp%> 
  {
  <%type%> <%iterName%>;
  
    for(<%tvar%> = 1; <%tvar%> <= size_of_dimension_<%arrayType%>(<%evar%>, 1); ++<%tvar%>) {
      <%if not acceptMetaModelicaGrammar() then '<%stateVar%> = get_memory_state();'%>
      <%stmtStuff%>
      <%body%>
      <%if not acceptMetaModelicaGrammar() then 'restore_memory_state(<%stateVar%>);'%>
    }
  }
  >>
end algStmtForGeneric_impl;

template algStmtWhile(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/)
 "Generates a while algorithm statement."
::=
match stmt
case STMT_WHILE(__) then
  let &preExp = buffer "" /*BUFD*/
  let var = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  <<
  while (1) {
    <%preExp%>
    if (!<%var%>) break;
    <%statementLst |> stmt => algStatement(stmt, context, &varDecls /*BUFD*/) ;separator="\n"%>
  }
  >>
end algStmtWhile;


template algStmtAssert(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/)
 "Generates an assert algorithm statement."
::=
match stmt
case STMT_ASSERT(source=SOURCE(info=info)) then
  assertCommon(cond, msg, context, &varDecls, info)
end algStmtAssert;

template algStmtTerminate(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/)
 "Generates an assert algorithm statement."
::=
match stmt
case STMT_TERMINATE(__) then
  let &preExp = buffer "" /*BUFD*/
  let msgVar = daeExp(msg, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  <<
  <%preExp%>
  MODELICA_TERMINATE(<%msgVar%>);
  >>
end algStmtTerminate;

template algStmtMatchcasesVarDeclsAndAssign(list<Exp> expList, Context context, Text &varDecls, Text &varAssign, Text &preExp)
::=
  (expList |> exp =>
    let decl = tempDecl(expTypeFromExpModelica(exp), &varDecls)
    // let content = daeExp(exp, context, &preExp, &varDecls)
    let lhs = scalarLhsCref(exp, context, &preExp, &varDecls)
    let &varAssign += '<%decl%> = <%lhs%>;' + "\n"
      '<%lhs%> = <%decl%>;'
    ; separator = "\n")
end algStmtMatchcasesVarDeclsAndAssign;

template algStmtFailure(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/)
 "Generates a failure() algorithm statement."
::=
match stmt
case STMT_FAILURE(__) then
  let tmp = tempDecl("modelica_boolean", &varDecls /*BUFD*/)
  let stmtBody = (body |> stmt =>
      algStatement(stmt, context, &varDecls /*BUFD*/)
    ;separator="\n")
  <<
  <%tmp%> = 0; /* begin failure */
  MMC_TRY()
    <%stmtBody%>
    <%tmp%> = 1;
  MMC_CATCH()
  if (<%tmp%>) MMC_THROW(); /* end failure */
  >>
end algStmtFailure;


template algStmtTry(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/)
 "Generates a try algorithm statement."
::=
match stmt
case STMT_TRY(__) then
  let body = (tryBody |> stmt =>
      algStatement(stmt, context, &varDecls /*BUFD*/)
    ;separator="\n")
  <<
  #error "Using STMT_TRY: This is deprecated, and should be matched with catch anyway."
  try {
    <%body%>
  }
  >>
end algStmtTry;


template algStmtCatch(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/)
 "Generates a catch algorithm statement."
::=
match stmt
case STMT_CATCH(__) then
  let body = (catchBody |> stmt =>
      algStatement(stmt, context, &varDecls /*BUFD*/)
    ;separator="\n")
  <<
  #error "Using STMT_CATCH: This is deprecated, and should be matched with catch anyway."
  catch (int i) {
    <%body%>
  }
  >>
end algStmtCatch;


template algStmtNoretcall(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/)
 "Generates a no return call algorithm statement."
::=
match stmt
case STMT_NORETCALL(__) then
  let &preExp = buffer "" /*BUFD*/
  let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  <<
  <%preExp%>
  <%expPart%>;
  >>
end algStmtNoretcall;


template algStmtWhen(DAE.Statement when, Context context, Text &varDecls /*BUFP*/)
 "Generates a when algorithm statement."
::=
match context
case SIMULATION(genDiscrete=true) then
  match when
  case STMT_WHEN(__) then
    let preIf = algStatementWhenPre(when, &varDecls /*BUFD*/)
    let statements = (statementLst |> stmt =>
        algStatement(stmt, context, &varDecls /*BUFD*/)
      ;separator="\n")
    let else = algStatementWhenElse(elseWhen, &varDecls /*BUFD*/)
    <<
    <%preIf%>
    if (<%helpVarIndices |> idx => 'edge(localData->helpVars[<%idx%>])' ;separator=" || "%>) {
      <%statements%>
    }
    <%else%>
    >>
  end match
case SIMULATION2(genDiscrete=true) then
  match when
  case STMT_WHEN(__) then
    let preIf = algStatementWhenPre(when, &varDecls /*BUFD*/)
    let statements = (statementLst |> stmt =>
        algStatement(stmt, context, &varDecls /*BUFD*/)
      ;separator="\n")
    let else = algStatementWhenElse(elseWhen, &varDecls /*BUFD*/)
    <<
    <%preIf%>
    if (<%helpVarIndices |> idx => 'edge(localData->helpVars[<%idx%>])' ;separator=" || "%>) {
      <%statements%>
    }
    <%else%>
    >>    
end algStmtWhen;


template algStatementWhenPre(DAE.Statement stmt, Text &varDecls /*BUFP*/)
 "Helper to algStmtWhen."
::=
  match stmt
  case STMT_WHEN(exp=ARRAY(array=el)) then
    let restPre = match elseWhen case SOME(ew) then
        algStatementWhenPre(ew, &varDecls /*BUFD*/)
      else
        ""
    let &preExp = buffer "" /*BUFD*/
    let assignments = algStatementWhenPreAssigns(el, helpVarIndices,
                                               &preExp /*BUFC*/,
                                               &varDecls /*BUFD*/)
    <<
    <%preExp%>
    <%assignments%>
    <%restPre%>
    >>
  case when as STMT_WHEN(__) then
    match helpVarIndices
    case {i} then
      let restPre = match when.elseWhen case SOME(ew) then
          algStatementWhenPre(ew, &varDecls /*BUFD*/)
        else
          ""
      let &preExp = buffer "" /*BUFD*/
      let res = daeExp(when.exp, contextSimulationDiscrete,
                     &preExp /*BUFC*/, &varDecls /*BUFD*/)
      <<
      <%preExp%>
      localData->helpVars[<%i%>] = <%res%>;
      <%restPre%>
      >>
end algStatementWhenPre;


template algStatementWhenElse(Option<DAE.Statement> stmt, Text &varDecls /*BUFP*/)
 "Helper to algStmtWhen."
::=
match stmt
case SOME(when as STMT_WHEN(__)) then
  let statements = (when.statementLst |> stmt =>
      algStatement(stmt, contextSimulationDiscrete, &varDecls /*BUFD*/)
    ;separator="\n")
  let else = algStatementWhenElse(when.elseWhen, &varDecls /*BUFD*/)
  let elseCondStr = (when.helpVarIndices |> idx =>
      'edge(localData->helpVars[<%idx%>])'
    ;separator=" || ")
  <<
  else if (<%elseCondStr%>) {
    <%statements%>
  }
  <%else%>
  >>
end algStatementWhenElse;


template algStatementWhenPreAssigns(list<Exp> exps, list<Integer> ints,
                           Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Helper to algStatementWhenPre.
  The lists exps and ints should be of the same length. Iterating over two
  lists like this is not so well supported in Susan, so it looks a bit ugly."
::=
  match exps
  case {} then ""
  case (firstExp :: restExps) then
    match ints
    case (firstInt :: restInts) then
      let rest = algStatementWhenPreAssigns(restExps, restInts,
                                          &preExp /*BUFC*/, &varDecls /*BUFD*/)
      let firstExpPart = daeExp(firstExp, contextSimulationDiscrete,
                              &preExp /*BUFC*/, &varDecls /*BUFD*/)
      <<
      localData->helpVars[<%firstInt%>] = <%firstExpPart%>;
      <%rest%>
      >>
end algStatementWhenPreAssigns;

template algStmtReinit(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/)
 "Generates an assigment algorithm statement."
::=
  match stmt
  case STMT_REINIT(__) then
    let &preExp = buffer "" /*BUFD*/
    let expPart1 = daeExp(var, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let expPart2 = daeExp(value, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    <<
    save(<%expPart1%>);
    <%preExp%>
    <%expPart1%> = <%expPart2%>;
    >>
end algStmtReinit;

template indexSpecFromCref(ComponentRef cr, Context context, Text &preExp /*BUFP*/,
                  Text &varDecls /*BUFP*/)
 "Helper to algStmtAssignArr.
  Currently works only for CREF_IDENT."
::=
match cr
case CREF_IDENT(subscriptLst=subs as (_ :: _)) then
  daeExpCrefRhsIndexSpec(subs, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
end indexSpecFromCref;


template elseExpr(DAE.Else else_, Context context, Text &varDecls /*BUFP*/)
 "Helper to algStmtIf."
 ::= 
  match else_
  case NOELSE(__) then
    ""
  case ELSEIF(__) then
    let &preExp = buffer "" /*BUFD*/
    let condExp = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    <<
    else {
      <%preExp%>
      if (<%condExp%>) {
        <%statementLst |> stmt =>
          algStatement(stmt, context, &varDecls /*BUFD*/)
        ;separator="\n"%>
      }
      <%elseExpr(else_, context, &varDecls /*BUFD*/)%>
    }
    >>
  case ELSE(__) then
    <<
    else {
      <%statementLst |> stmt =>
        algStatement(stmt, context, &varDecls /*BUFD*/)
      ;separator="\n"%>
    }
    >>
end elseExpr;

template scalarLhsCref(Exp ecr, Context context, Text &preExp, Text &varDecls)
 "Generates the left hand side (for use on left hand side) of a component
  reference."
::=
  match ecr
  case CREF(componentRef = cr, ty = ET_FUNCTION_REFERENCE_VAR(__)) then
    '*((modelica_fnptr*)&_<%crefStr(cr)%>)'
  case ecr as CREF(componentRef=CREF_IDENT(__)) then
    if crefNoSub(ecr.componentRef) then
      contextCref(ecr.componentRef, context)
    else
      daeExpCrefRhs(ecr, context, &preExp, &varDecls)
  case ecr as CREF(componentRef=CREF_QUAL(__)) then
    contextCref(ecr.componentRef, context)
  case ecr as CREF(componentRef=WILD(__)) then
    ''
  else
    "ONLY_IDENT_OR_QUAL_CREF_SUPPORTED_SLHS"
end scalarLhsCref;


template rhsCref(ComponentRef cr, ExpType ty)
 "Like cref but with cast if type is integer."
::=
  match cr
  case CREF_IDENT(__) then '<%rhsCrefType(ty)%><%ident%>'
  case CREF_QUAL(__)  then '<%rhsCrefType(ty)%><%ident%>.<%rhsCref(componentRef,ty)%>'
  else "rhsCref:ERROR"
end rhsCref;


template rhsCrefType(ExpType type)
 "Helper to rhsCref."
::=
  match type
  case ET_INT(__) then "(modelica_integer)"
  case ET_ENUMERATION(__) then "(modelica_integer)"
  //else ""
end rhsCrefType;
  

template daeExp(Exp exp, Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Generates code for an expression."
::=
  match exp
  case e as ICONST(__)          then '(modelica_integer) <%integer%>' /* Yes, we need to cast int to long on 64-bit arch... */
  case e as RCONST(__)          then real
  case e as SCONST(__)          then daeExpSconst(string, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as BCONST(__)          then if bool then "(1)" else "(0)"
  case e as ENUM_LITERAL(__)    then index
  case e as CREF(__)            then daeExpCrefRhs(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as BINARY(__)          then daeExpBinary(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as UNARY(__)           then daeExpUnary(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as LBINARY(__)         then daeExpLbinary(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as LUNARY(__)          then daeExpLunary(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as RELATION(__)        then daeExpRelation(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as IFEXP(__)           then daeExpIf(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as CALL(__)            then daeExpCall(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as ARRAY(__)           then daeExpArray(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as MATRIX(__)          then daeExpMatrix(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as CAST(__)            then daeExpCast(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as ASUB(__)            then daeExpAsub(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as SIZE(__)            then daeExpSize(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as REDUCTION(__)       then daeExpReduction(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as LIST(__)            then daeExpList(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as CONS(__)            then daeExpCons(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as META_TUPLE(__)      then daeExpMetaTuple(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as META_OPTION(__)     then daeExpMetaOption(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as METARECORDCALL(__)  then daeExpMetarecordcall(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as MATCHEXPRESSION(__) then daeExpMatch(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as BOX(__)             then daeExpBox(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as UNBOX(__)           then daeExpUnbox(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as SHARED_LITERAL(__)  then daeExpSharedLiteral(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  else '<%\n%>#error "UNKNOWN_EXP <%ExpressionDump.printExpStr(exp)%>"<%\n%>'
end daeExp;


template daeExpSconst(String string, Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Generates code for a string constant."
::=
  '"<%Util.escapeModelicaStringToCString(string)%>"'
end daeExpSconst;

template daeExpCrefRhs(Exp exp, Context context, Text &preExp /*BUFP*/,
                       Text &varDecls /*BUFP*/)
 "Generates code for a component reference on the right hand side of an
 expression."
::=
  match exp
  // A record cref without subscripts (i.e. a record instance) is handled
  // by daeExpRecordCrefRhs only in a simulation context, not in a function.
  case CREF(componentRef = cr, ty = t as ET_COMPLEX(complexClassType = RECORD(path = _))) then
    match context case FUNCTION_CONTEXT(__) then
      daeExpCrefRhs2(exp, context, &preExp, &varDecls)
    else
      daeExpRecordCrefRhs(t, cr, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case CREF(componentRef = cr, ty = ET_FUNCTION_REFERENCE_FUNC(__)) then
    '((modelica_fnptr)boxptr_<%crefFunctionName(cr)%>)'
  case CREF(componentRef = cr, ty = ET_FUNCTION_REFERENCE_VAR(__)) then
    '((modelica_fnptr) _<%crefStr(cr)%>)'
  else daeExpCrefRhs2(exp, context, &preExp, &varDecls)
end daeExpCrefRhs;

template daeExpCrefRhs2(Exp ecr, Context context, Text &preExp /*BUFP*/,
                       Text &varDecls /*BUFP*/)
 "Generates code for a component reference."
::=
  match ecr
  case ecr as CREF(componentRef=cr, ty=ty) then
    let box = daeExpCrefRhsArrayBox(ecr, context, &preExp, &varDecls)
    if box then
      box
    else if crefIsScalar(cr, context) then
      let cast = match ty case ET_INT(__) then "(modelica_integer)"
                          case ET_ENUMERATION(__) then "(modelica_integer)" //else ""
      '<%cast%><%contextCref(cr,context)%>'
    else 
     if crefSubIsScalar(cr) then
      // The array subscript results in a scalar
      let arrName = contextCref(crefStripLastSubs(cr), context)
      let arrayType = expTypeArray(ty)
      let dimsLenStr = listLength(crefSubs(cr))
      let dimsValuesStr = (crefSubs(cr) |> INDEX(__) =>
          daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
        ;separator=", ")
      match arrayType
        case "metatype_array" then
          'arrayGet(<%arrName%>,<%dimsValuesStr%>) /* DAE.CREF */'
        else
          <<
          (*<%arrayType%>_element_addr(&<%arrName%>, <%dimsLenStr%>, <%dimsValuesStr%>))
          >>
    else
      // The array subscript denotes a slice

      let arrName = contextArrayCref(cr, context)
      let arrayType = expTypeArray(ty)
      let tmp = tempDecl(arrayType, &varDecls /*BUFD*/)
      let spec1 = daeExpCrefRhsIndexSpec(crefSubs(cr), context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
      let &preExp += 'index_alloc_<%arrayType%>(&<%arrName%>, &<%spec1%>, &<%tmp%>);<%\n%>'
      tmp
end daeExpCrefRhs2;

template daeExpCrefRhsIndexSpec(list<Subscript> subs, Context context,
                                Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Helper to daeExpCrefRhs."
::=
  let nridx_str = listLength(subs)
  let idx_str = (subs |> sub =>
      match sub
      case INDEX(__) then
        let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
        <<
        (0), make_index_array(1, (int) <%expPart%>), 'S'
        >>
      case WHOLEDIM(__) then
        <<
        (1), (int*)0, 'W'
        >>
      case SLICE(__) then
        let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
        let tmp = tempDecl("modelica_integer", &varDecls /*BUFD*/)
        let &preExp += '<%tmp%> = size_of_dimension_integer_array(<%expPart%>, 1);<%\n%>'
        <<
        (int) <%tmp%>, integer_array_make_index_array(&<%expPart%>), 'A'
        >>
    ;separator=", ")
  let tmp = tempDecl("index_spec_t", &varDecls /*BUFD*/)
  let &preExp += 'create_index_spec(&<%tmp%>, <%nridx_str%>, <%idx_str%>);<%\n%>'
  tmp
end daeExpCrefRhsIndexSpec;


template daeExpCrefRhsArrayBox(Exp ecr, Context context, Text &preExp /*BUFP*/,
                               Text &varDecls /*BUFP*/)
 "Helper to daeExpCrefRhs."
::=
match ecr
case ecr as CREF(ty=ET_ARRAY(ty=aty,arrayDimensions=dims)) then
  match context
  case FUNCTION_CONTEXT(__) then ''
  else
    // For context simulation and other array variables must be boxed into a real_array
    // object since they are represented only in a double array.
    let tmpArr = tempDecl(expTypeArray(aty), &varDecls /*BUFD*/)
    let dimsLenStr = listLength(dims)
    let dimsValuesStr = (dims |> dim => dimension(dim) ;separator=", ")
    let type = expTypeShort(aty)
    let &preExp += '<%type%>_array_create(&<%tmpArr%>, ((modelica_<%type%>*)&(<%arrayCrefCStr(ecr.componentRef)%>)), <%dimsLenStr%>, <%dimsValuesStr%>);<%\n%>'
    tmpArr
end daeExpCrefRhsArrayBox;


template daeExpRecordCrefRhs(DAE.ExpType ty, ComponentRef cr, Context context, Text &preExp /*BUFP*/,
                       Text &varDecls /*BUFP*/)
::=
match ty
case ET_COMPLEX(name = record_path, varLst = var_lst) then
  let vars = var_lst |> v => daeExp(makeCrefRecordExp(cr,v), context, &preExp, &varDecls) 
             ;separator=", "
  let record_type_name = underscorePath(record_path)
  let ret_type = '<%record_type_name%>_rettype'
  let ret_var = tempDecl(ret_type, &varDecls)
  let &preExp += '<%ret_var%> = _<%record_type_name%>(<%vars%>);<%\n%>'
  '<%ret_var%>.<%ret_type%>_1'
end daeExpRecordCrefRhs;

template daeExpBinary(Exp exp, Context context, Text &preExp /*BUFP*/,
                      Text &varDecls /*BUFP*/)
 "Generates code for a binary expression."
::=

match exp
case BINARY(__) then
  let e1 = daeExp(exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  let e2 = daeExp(exp2, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  match operator
  case ADD(ty = ET_STRING(__)) then
    let tmpStr = tempDecl("modelica_string", &varDecls /*BUFD*/)
    let &preExp += if acceptMetaModelicaGrammar() then
        '<%tmpStr%> = stringAppend(<%e1%>,<%e2%>);<%\n%>'
      else
        '<%tmpStr%> = cat_modelica_string(<%e1%>,<%e2%>);<%\n%>'
    tmpStr
  case ADD(__) then '(<%e1%> + <%e2%>)'
  case SUB(__) then '(<%e1%> - <%e2%>)'
  case MUL(__) then '(<%e1%> * <%e2%>)'
  case DIV(__) then '(<%e1%> / <%e2%>)'
  case POW(__) then 'pow((modelica_real)<%e1%>, (modelica_real)<%e2%>)'
  case UMINUS(__) then daeExpUnary(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/) 
  case ADD_ARR(__) then
    let type = match ty case ET_ARRAY(ty=ET_INT(__)) then "integer_array" 
                        case ET_ARRAY(ty=ET_ENUMERATION(__)) then "integer_array"
                        else "real_array"
    let var = tempDecl(type, &varDecls /*BUFD*/)
    let &preExp += 'add_alloc_<%type%>(&<%e1%>, &<%e2%>, &<%var%>);<%\n%>'
    '<%var%>'
  case SUB_ARR(__) then
    let type = match ty case ET_ARRAY(ty=ET_INT(__)) then "integer_array" 
                        case ET_ARRAY(ty=ET_ENUMERATION(__)) then "integer_array"
                        else "real_array"
    let var = tempDecl(type, &varDecls /*BUFD*/)
    let &preExp += 'sub_alloc_<%type%>(&<%e1%>, &<%e2%>, &<%var%>);<%\n%>'
    '<%var%>'
  case MUL_ARR(__) then  'daeExpBinary:ERR for MUL_ARR'  
  case DIV_ARR(__) then  'daeExpBinary:ERR for DIV_ARR'  
  case MUL_SCALAR_ARRAY(__) then
    let type = match ty case ET_ARRAY(ty=ET_INT(__)) then "integer_array" 
                        case ET_ARRAY(ty=ET_ENUMERATION(__)) then "integer_array"
                        else "real_array"
    let var = tempDecl(type, &varDecls /*BUFD*/)
    let &preExp += 'mul_alloc_scalar_<%type%>(<%e1%>, &<%e2%>, &<%var%>);<%\n%>'
    '<%var%>'    
  case MUL_ARRAY_SCALAR(__) then
    let type = match ty case ET_ARRAY(ty=ET_INT(__)) then "integer_array" 
                        case ET_ARRAY(ty=ET_ENUMERATION(__)) then "integer_array"
                        else "real_array"
    let var = tempDecl(type, &varDecls /*BUFD*/)
    let &preExp += 'mul_alloc_<%type%>_scalar(&<%e1%>, <%e2%>, &<%var%>);<%\n%>'
    '<%var%>'  
  case ADD_SCALAR_ARRAY(__) then 'daeExpBinary:ERR for ADD_SCALAR_ARRAY'
  case ADD_ARRAY_SCALAR(__) then 'daeExpBinary:ERR for ADD_ARRAY_SCALAR'
  case SUB_SCALAR_ARRAY(__) then 'daeExpBinary:ERR for SUB_SCALAR_ARRAY'
  case SUB_ARRAY_SCALAR(__) then 'daeExpBinary:ERR for SUB_ARRAY_SCALAR'
  case MUL_SCALAR_PRODUCT(__) then
    let type = match ty case ET_ARRAY(ty=ET_INT(__)) then "integer_scalar" 
                        case ET_ARRAY(ty=ET_ENUMERATION(__)) then "integer_scalar"
                        else "real_scalar"
    'mul_<%type%>_product(&<%e1%>, &<%e2%>)'
  case MUL_MATRIX_PRODUCT(__) then
    let typeShort = match ty case ET_ARRAY(ty=ET_INT(__)) then "integer" 
                             case ET_ARRAY(ty=ET_ENUMERATION(__)) then "integer"
                             else "real"
    let type = '<%typeShort%>_array'
    let var = tempDecl(type, &varDecls /*BUFD*/)
    let &preExp += 'mul_alloc_<%typeShort%>_matrix_product_smart(&<%e1%>, &<%e2%>, &<%var%>);<%\n%>'
    '<%var%>'
  case DIV_ARRAY_SCALAR(__) then
    let type = match ty case ET_ARRAY(ty=ET_INT(__)) then "integer_array" 
                        case ET_ARRAY(ty=ET_ENUMERATION(__)) then "integer_array"
                        else "real_array"
    let var = tempDecl(type, &varDecls /*BUFD*/)
    let &preExp += 'div_alloc_<%type%>_scalar(&<%e1%>, <%e2%>, &<%var%>);<%\n%>'
    '<%var%>'
  case DIV_SCALAR_ARRAY(__) then 'daeExpBinary:ERR for DIV_SCALAR_ARRAY'
  case POW_ARRAY_SCALAR(__) then 'daeExpBinary:ERR for POW_ARRAY_SCALAR'
  case POW_SCALAR_ARRAY(__) then 'daeExpBinary:ERR for POW_SCALAR_ARRAY'
  case POW_ARR(__) then 'daeExpBinary:ERR for POW_ARR'
  case POW_ARR2(__) then 'daeExpBinary:ERR for POW_ARR2'
  else "daeExpBinary:ERR"
end daeExpBinary;


template daeExpUnary(Exp exp, Context context, Text &preExp /*BUFP*/,
                     Text &varDecls /*BUFP*/)
 "Generates code for a unary expression."
::=
match exp
case UNARY(__) then
  let e = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  match operator
  case UMINUS(__)     then '(-<%e%>)'
  case UPLUS(__)      then '(<%e%>)'
  case UMINUS_ARR(ty=ET_ARRAY(ty=ET_REAL(__))) then
    let &preExp += 'usub_real_array(&<%e%>);<%\n%>'
    '<%e%>'
  case UMINUS_ARR(__) then 'unary minus for non-real arrays not implemented'
  case UPLUS_ARR(__)  then "UPLUS_ARR_NOT_IMPLEMENTED"
  else "daeExpUnary:ERR"
end daeExpUnary;


template daeExpLbinary(Exp exp, Context context, Text &preExp /*BUFP*/,
                       Text &varDecls /*BUFP*/)
 "Generates code for a logical binary expression."
::=
match exp
case LBINARY(__) then
  let e1 = daeExp(exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  let e2 = daeExp(exp2, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  match operator
  case AND(__) then '(<%e1%> && <%e2%>)'
  case OR(__)  then '(<%e1%> || <%e2%>)'
  else "daeExpLbinary:ERR"
end daeExpLbinary;


template daeExpLunary(Exp exp, Context context, Text &preExp /*BUFP*/,
                      Text &varDecls /*BUFP*/)
 "Generates code for a logical unary expression."
::=
match exp
case LUNARY(__) then
  let e = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  match operator
  case NOT(__) then '(!<%e%>)'
end daeExpLunary;


template daeExpRelation(Exp exp, Context context, Text &preExp /*BUFP*/,
                        Text &varDecls /*BUFP*/)
 "Generates code for a relation expression."
::=
match exp
case rel as RELATION(__) then
  let simRel = daeExpRelationSim(rel, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  if simRel then
    simRel
  else
    let e1 = daeExp(rel.exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let e2 = daeExp(rel.exp2, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    match rel.operator
    
    case LESS(ty = ET_BOOL(__))             then '(!<%e1%> && <%e2%>)'
    case LESS(ty = ET_STRING(__))           then '(stringCompare(<%e1%>, <%e2%>) < 0)'
    case LESS(ty = ET_INT(__))              then '(<%e1%> < <%e2%>)'
    case LESS(ty = ET_REAL(__))             then '(<%e1%> < <%e2%>)'
    case LESS(ty = ET_ENUMERATION(__))      then '(<%e1%> < <%e2%>)'
    
    case GREATER(ty = ET_BOOL(__))          then '(<%e1%> && !<%e2%>)'
    case GREATER(ty = ET_STRING(__))        then '(stringCompare(<%e1%>, <%e2%>) > 0)'
    case GREATER(ty = ET_INT(__))           then '(<%e1%> > <%e2%>)'
    case GREATER(ty = ET_REAL(__))          then '(<%e1%> > <%e2%>)'
    case GREATER(ty = ET_ENUMERATION(__))   then '(<%e1%> > <%e2%>)'
    
    case LESSEQ(ty = ET_BOOL(__))           then '(!<%e1%> || <%e2%>)'
    case LESSEQ(ty = ET_STRING(__))         then '(stringCompare(<%e1%>, <%e2%>) <= 0)'
    case LESSEQ(ty = ET_INT(__))            then '(<%e1%> <= <%e2%>)'
    case LESSEQ(ty = ET_REAL(__))           then '(<%e1%> <= <%e2%>)'
    case LESSEQ(ty = ET_ENUMERATION(__))    then '(<%e1%> <= <%e2%>)'
    
    case GREATEREQ(ty = ET_BOOL(__))        then '(<%e1%> || !<%e2%>)'
    case GREATEREQ(ty = ET_STRING(__))      then '(stringCompare(<%e1%>, <%e2%>) >= 0)'
    case GREATEREQ(ty = ET_INT(__))         then '(<%e1%> >= <%e2%>)'
    case GREATEREQ(ty = ET_REAL(__))        then '(<%e1%> >= <%e2%>)'
    case GREATEREQ(ty = ET_ENUMERATION(__)) then '(<%e1%> >= <%e2%>)'
    
    case EQUAL(ty = ET_BOOL(__))            then '((!<%e1%> && !<%e2%>) || (<%e1%> && <%e2%>))'
    case EQUAL(ty = ET_STRING(__))          then '(stringEqual(<%e1%>, <%e2%>))'
    case EQUAL(ty = ET_INT(__))             then '(<%e1%> == <%e2%>)'
    case EQUAL(ty = ET_REAL(__))            then '(<%e1%> == <%e2%>)'
    case EQUAL(ty = ET_ENUMERATION(__))     then '(<%e1%> == <%e2%>)'    
    
    case NEQUAL(ty = ET_BOOL(__))           then '((!<%e1%> && <%e2%>) || (<%e1%> && !<%e2%>))'
    case NEQUAL(ty = ET_STRING(__))         then '(!stringEqual(<%e1%>, <%e2%>))'
    case NEQUAL(ty = ET_INT(__))            then '(<%e1%> != <%e2%>)'
    case NEQUAL(ty = ET_REAL(__))           then '(<%e1%> != <%e2%>)'
    case NEQUAL(ty = ET_ENUMERATION(__))    then '(<%e1%> != <%e2%>)'
    
    else "daeExpRelation:ERR"
end daeExpRelation;


template daeExpRelationSim(Exp exp, Context context, Text &preExp /*BUFP*/,
                           Text &varDecls /*BUFP*/)
 "Helper to daeExpRelation."
::=
match exp
case rel as RELATION(__) then
  match context
  case SIMULATION(__) then
    let e1 = daeExp(rel.exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let e2 = daeExp(rel.exp2, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let res = tempDecl("modelica_boolean", &varDecls /*BUFD*/)
    match rel.operator
    case LESS(__) then
      let &preExp += 'RELATIONLESS(<%res%>, <%e1%>, <%e2%>);<%\n%>'
      res
    case LESSEQ(__) then
      let &preExp += 'RELATIONLESSEQ(<%res%>, <%e1%>, <%e2%>);<%\n%>'
      res
    case GREATER(__) then
      let &preExp += 'RELATIONGREATER(<%res%>, <%e1%>, <%e2%>);<%\n%>'
      res
    case GREATEREQ(__) then
      let &preExp += 'RELATIONGREATEREQ(<%res%>, <%e1%>, <%e2%>);<%\n%>'
      res
    end match
  case SIMULATION2(genDiscrete=false) then
     match rel.optionExpisASUB
     case NONE() then
        let e1 = daeExp(rel.exp1, context, &preExp /*BUFC*/, &varDecls /*BUFC*/)
        let e2 = daeExp(rel.exp2, context, &preExp /*BUFC*/, &varDecls /*BUFC*/)
        let res = tempDecl("modelica_boolean", &varDecls /*BUFC*/)
        match rel.operator
        case LESS(__) then
          let &preExp += 'RELATIONTOZC(<%res%>, <%e1%>, <%e2%>, <%rel.index%>,Less,<);<%\n%>'
          res
        case LESSEQ(__) then
          let &preExp += 'RELATIONTOZC(<%res%>, <%e1%>, <%e2%>, <%rel.index%>,LessEq,<=);<%\n%>'
          res
        case GREATER(__) then
          let &preExp += 'RELATIONTOZC(<%res%>, <%e1%>, <%e2%>, <%rel.index%>,Greater,>);<%\n%>'
          res
        case GREATEREQ(__) then
          let &preExp += 'RELATIONTOZC(<%res%>, <%e1%>, <%e2%>, <%rel.index%>,GreaterEq,>=);<%\n%>'
          res
        end match
    case SOME((exp,i,j)) then
	    let e1 = daeExp(rel.exp1, context, &preExp /*BUFC*/, &varDecls /*BUFC*/)
	    let e2 = daeExp(rel.exp2, context, &preExp /*BUFC*/, &varDecls /*BUFC*/)
	    let iterator = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFC*/)
	    let res = tempDecl("modelica_boolean", &varDecls /*BUFC*/)
	    //let e3 = daeExp(createArray(i), context, &preExp /*BUFC*/, &varDecls /*BUFC*/)
	    match rel.operator
	    case LESS(__) then
	      let &preExp += 'RELATIONTOZC(<%res%>, <%e1%>, <%e2%>, <%rel.index%> + (<%iterator%> - <%i%>)/<%j%>,Less,<);<%\n%>'
	      res
	    case LESSEQ(__) then
	      let &preExp += 'RELATIONTOZC(<%res%>, <%e1%>, <%e2%>, <%rel.index%> + (<%iterator%> - <%i%>)/<%j%>,LessEq,<=);<%\n%>'
	      res
	    case GREATER(__) then
	      let &preExp += 'RELATIONTOZC(<%res%>, <%e1%>, <%e2%>, <%rel.index%> + (<%iterator%> - <%i%>)/<%j%>,Greater,>);<%\n%>'
	      res
	    case GREATEREQ(__) then
	      let &preExp += 'RELATIONTOZC(<%res%>, <%e1%>, <%e2%>, <%rel.index%> + (<%iterator%> - <%i%>)/<%j%>,GreaterEq,>=);<%\n%>'
	      res
        end match
      end match
   case SIMULATION2(genDiscrete=true) then
     match rel.optionExpisASUB
     case NONE() then
        let e1 = daeExp(rel.exp1, context, &preExp /*BUFC*/, &varDecls /*BUFC*/)
        let e2 = daeExp(rel.exp2, context, &preExp /*BUFC*/, &varDecls /*BUFC*/)
        let res = tempDecl("modelica_boolean", &varDecls /*BUFC*/)
        match rel.operator
        case LESS(__) then
          let &preExp += 'SAVEZEROCROSS(<%res%>, <%e1%>, <%e2%>, <%rel.index%>,Less,<);<%\n%>'
          res
        case LESSEQ(__) then
          let &preExp += 'SAVEZEROCROSS(<%res%>, <%e1%>, <%e2%>, <%rel.index%>,LessEq,<=);<%\n%>'
          res
        case GREATER(__) then
          let &preExp += 'SAVEZEROCROSS(<%res%>, <%e1%>, <%e2%>, <%rel.index%>,Greater,>);<%\n%>'
          res
        case GREATEREQ(__) then
          let &preExp += 'SAVEZEROCROSS(<%res%>, <%e1%>, <%e2%>, <%rel.index%>,GreaterEq,>=);<%\n%>'
          res
        end match
    case SOME((exp,i,j)) then
         let e1 = daeExp(rel.exp1, context, &preExp /*BUFC*/, &varDecls /*BUFC*/)
         let e2 = daeExp(rel.exp2, context, &preExp /*BUFC*/, &varDecls /*BUFC*/)
         let res = tempDecl("modelica_boolean", &varDecls /*BUFC*/)
         //let e3 = daeExp(createArray(i), context, &preExp /*BUFC*/, &varDecls /*BUFC*/)
         let iterator = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFC*/)
		 match rel.operator
		 case LESS(__) then
		    let &preExp += 'SAVEZEROCROSS(<%res%>, <%e1%>, <%e2%>, <%rel.index%> + (<%iterator%> - <%i%>)/<%j%>,Less,<);<%\n%>'
		    res
		 case LESSEQ(__) then
		    let &preExp += 'SAVEZEROCROSS(<%res%>, <%e1%>, <%e2%>, <%rel.index%> + (<%iterator%> - <%i%>)/<%j%>,LessEq,<=);<%\n%>'
		    res
		 case GREATER(__) then
		    let &preExp += 'SAVEZEROCROSS(<%res%>, <%e1%>, <%e2%>, <%rel.index%> + (<%iterator%> - <%i%>)/<%j%>,Greater,>);<%\n%>'
		    res
		 case GREATEREQ(__) then
		    let &preExp += 'SAVEZEROCROSS(<%res%>, <%e1%>, <%e2%>,<%rel.index%> + (<%iterator%> - <%i%>)/<%j%>,GreaterEq,>=);<%\n%>'
		    res
   	     end match
   	   end match
	end match
end match
end daeExpRelationSim;

template daeExpIf(Exp exp, Context context, Text &preExp /*BUFP*/,
                  Text &varDecls /*BUFP*/)
 "Generates code for an if expression."
::=
match exp
case IFEXP(__) then
  let condExp = daeExp(expCond, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  let &preExpThen = buffer "" /*BUFD*/
  let eThen = daeExp(expThen, context, &preExpThen /*BUFC*/, &varDecls /*BUFD*/)
  let &preExpElse = buffer "" /*BUFD*/
  let eElse = daeExp(expElse, context, &preExpElse /*BUFC*/, &varDecls /*BUFD*/)
  let shortIfExp = if preExpThen then "" else if preExpElse then "" else "x"
  (if shortIfExp
    then
      // Safe to do if eThen and eElse don't emit pre-expressions
      '(<%condExp%>?<%eThen%>:<%eElse%>)'
    else
      let condVar = tempDecl("modelica_boolean", &varDecls /*BUFD*/)
      let resVarType = expTypeFromExpArrayIf(expThen)
      let resVar = tempDecl(resVarType, &varDecls /*BUFD*/)
      let &preExp +=  
      <<
      <%condVar%> = (modelica_boolean)<%condExp%>;
      if (<%condVar%>) {
        <%preExpThen%>
        <%resVar%> = (<%resVarType%>)<%eThen%>;
      } else {
        <%preExpElse%>
        <%resVar%> = (<%resVarType%>)<%eElse%>;
      }<%\n%>
      >>
      resVar)
end daeExpIf;


template daeExpCall(Exp call, Context context, Text &preExp /*BUFP*/,
                    Text &varDecls /*BUFP*/)
 "Generates code for a function call."
::=
  match call
  // special builtins
  case CALL(tuple_=false, builtin=true,
            path=IDENT(name="DIVISION"),
            expLst={e1, e2, DAE.SCONST(string=string)}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls)
    let var2 = daeExp(e2, context, &preExp, &varDecls)
    let var3 = Util.escapeModelicaStringToCString(string)
    'DIVISION(<%var1%>,<%var2%>,"<%var3%>")'
  
  case CALL(tuple_=false, builtin=true, ty=ty, 
            path=IDENT(name="DIVISION_ARRAY_SCALAR"),
            expLst={e1, e2, DAE.SCONST(string=string)}) then
    let type = match ty case ET_ARRAY(ty=ET_INT(__)) then "integer_array" 
                        case ET_ARRAY(ty=ET_ENUMERATION(__)) then "integer_array"
                        else "real_array"
    let var = tempDecl(type, &varDecls)
    let var1 = daeExp(e1, context, &preExp, &varDecls)
    let var2 = daeExp(e2, context, &preExp, &varDecls)
    let var3 = Util.escapeModelicaStringToCString(string)
    let &preExp += 'division_alloc_<%type%>_scalar(&<%var1%>, <%var2%>, &<%var%>,"<%var3%>");<%\n%>'
    '<%var%>'
  
  case CALL(tuple_=false, builtin=true,
            path=IDENT(name="der"), expLst={arg as CREF(__)}) then
    '$P$DER<%cref(arg.componentRef)%>'
  case CALL(tuple_=false, builtin=true,
            path=IDENT(name="pre"), expLst={arg as CREF(__)}) then
    let retType = '<%expTypeArrayIf(arg.ty)%>'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let cast = match arg.ty case ET_INT(__) then "(modelica_integer)" 
                            case ET_ENUMERATION(__) then "(modelica_integer)" //else ""
    let &preExp += '<%retVar%> = <%cast%>pre(<%cref(arg.componentRef)%>);<%\n%>'
    '<%retVar%>'
  
  case CALL(tuple_=false, builtin=true,
            path=IDENT(name="max"), expLst={e1,e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls)
    let var2 = daeExp(e2, context, &preExp, &varDecls)
    'std::max(<%var1%>,<%var2%>)'
  
  case CALL(tuple_=false, builtin=true, ty = ET_INT(),
            path=IDENT(name="min"), expLst={e1,e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls)
    let var2 = daeExp(e2, context, &preExp, &varDecls)
    'std::min((modelica_integer)<%var1%>,(modelica_integer)<%var2%>)'
  
  case CALL(tuple_=false, builtin=true, ty = ET_ENUMERATION(__),
            path=IDENT(name="min"), expLst={e1,e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls)
    let var2 = daeExp(e2, context, &preExp, &varDecls)
    'std::min((modelica_integer)<%var1%>,(modelica_integer)<%var2%>)'  
  
  case CALL(tuple_=false, builtin=true, ty = ET_REAL(),
            path=IDENT(name="min"), expLst={e1,e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls)
    let var2 = daeExp(e2, context, &preExp, &varDecls)
    'std::min(<%var1%>,<%var2%>)'
  
  case CALL(tuple_=false, builtin=true,
            path=IDENT(name="abs"), expLst={e1}, ty = ET_INT()) then
    let var1 = daeExp(e1, context, &preExp, &varDecls)
    'std::abs(<%var1%>)'
  
  case CALL(tuple_=false, builtin=true,
            path=IDENT(name="abs"), expLst={e1}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls)
    'fabs(<%var1%>)'
  
    //sqrt 
  case CALL(tuple_=false, builtin=true,
            path=IDENT(name="sqrt"),
            expLst={e1}) then
    //relation = DAE.LBINARY(e1,DAE.GREATEREQ(ET_REAL()),DAE.RCONST(0))
    //string = DAE.SCONST('Model error: Argument of sqrt should  >= 0')
    //let retPre = assertCommon(relation,s, context, &varDecls)
    let retPre = assertCommon(createAssertforSqrt(e1),createDAEString("Model error: Argument of sqrt should be >= 0"), context, &varDecls, dummyInfo)
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let retType = '<%funName%>_rettype'
    let &preExp += '<%retPre%>'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = <%daeExpCallBuiltinPrefix(builtin)%><%funName%>(<%argStr%>);<%\n%>'
    if builtin then '<%retVar%>' else '<%retVar%>.<%retType%>_1'
  
  case CALL(tuple_=false, builtin=true,
            path=IDENT(name="div"), expLst={e1,e2}, ty = ET_INT()) then
    let var1 = daeExp(e1, context, &preExp, &varDecls)
    let var2 = daeExp(e2, context, &preExp, &varDecls)
    'ldiv(<%var1%>,<%var2%>).quot'
  
  case CALL(tuple_=false, builtin=true,
            path=IDENT(name="div"), expLst={e1,e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls)
    let var2 = daeExp(e2, context, &preExp, &varDecls)
    'trunc(<%var1%>/<%var2%>)'
  
  case CALL(tuple_=false, builtin=true,
            path=IDENT(name="mod"), expLst={e1,e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls)
    let var2 = daeExp(e2, context, &preExp, &varDecls)
    'modelica_mod_<%expTypeShort(ty)%>(<%var1%>,<%var2%>)'
    
  case CALL(tuple_=false, builtin=true,
            path=IDENT(name="max"), expLst={array}) then
    let expVar = daeExp(array, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let arr_tp_str = '<%expTypeFromExpArray(array)%>'
    let tvar = tempDecl(expTypeFromExpModelica(array), &varDecls /*BUFD*/)
    let &preExp += '<%tvar%> = max_<%arr_tp_str%>(&<%expVar%>);<%\n%>'
    '<%tvar%>'
  
  case CALL(tuple_=false, builtin=true,
            path=IDENT(name="min"), expLst={array}) then
    let expVar = daeExp(array, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let arr_tp_str = '<%expTypeFromExpArray(array)%>'
    let tvar = tempDecl(expTypeFromExpModelica(array), &varDecls /*BUFD*/)
    let &preExp += '<%tvar%> = min_<%arr_tp_str%>(&<%expVar%>);<%\n%>'
    '<%tvar%>'

  case CALL(tuple_=false, builtin=true,
            path=IDENT(name="promote"), expLst={A, n}) then
    let var1 = daeExp(A, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let var2 = daeExp(n, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let arr_tp_str = '<%expTypeFromExpArray(A)%>'
    let tvar = tempDecl(arr_tp_str, &varDecls /*BUFD*/)
    let &preExp += 'promote_alloc_<%arr_tp_str%>(&<%var1%>, <%var2%>, &<%tvar%>);<%\n%>'
    '<%tvar%>'
  
  case CALL(tuple_=false, builtin=true,
            path=IDENT(name="transpose"), expLst={A}) then
    let var1 = daeExp(A, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let arr_tp_str = '<%expTypeFromExpArray(A)%>'
    let tvar = tempDecl(arr_tp_str, &varDecls /*BUFD*/)
    let &preExp += 'transpose_alloc_<%arr_tp_str%>(&<%var1%>, &<%tvar%>);<%\n%>'
    '<%tvar%>'
  
  case CALL(tuple_=false, builtin=true,
            path=IDENT(name="cross"), expLst={v1, v2}) then
    let var1 = daeExp(v1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let var2 = daeExp(v2, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let arr_tp_str = '<%expTypeFromExpArray(v1)%>'
    let tvar = tempDecl(arr_tp_str, &varDecls /*BUFD*/)
    let &preExp += 'cross_alloc_<%arr_tp_str%>(&<%var1%>, &<%var2%>, &<%tvar%>);<%\n%>'
    '<%tvar%>'
  
  case CALL(tuple_=false, builtin=true,
            path=IDENT(name="identity"), expLst={A}) then
    let var1 = daeExp(A, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let arr_tp_str = '<%expTypeFromExpArray(A)%>'
    let tvar = tempDecl(arr_tp_str, &varDecls /*BUFD*/)
    let &preExp += 'identity_alloc_<%arr_tp_str%>(<%var1%>, &<%tvar%>);<%\n%>'
    '<%tvar%>'

  case CALL(tuple_=false, builtin=true,
            path=IDENT(name="rem"),
            expLst={e1, e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls)
    let var2 = daeExp(e2, context, &preExp, &varDecls)
    let typeStr = expTypeFromExpShort(e1)
    'modelica_rem_<%typeStr%>(<%var1%>,<%var2%>)'
  
  case CALL(tuple_=false, builtin=true,
            path=IDENT(name="String"),
            expLst={s, format}) then
    let tvar = tempDecl("modelica_string", &varDecls /*BUFD*/)
    let sExp = daeExp(s, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let formatExp = daeExp(format, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let typeStr = expTypeFromExpModelica(s)
    let &preExp += '<%tvar%> = <%typeStr%>_to_modelica_string_format(<%sExp%>, <%formatExp%>);<%\n%>'
    '<%tvar%>'
  

  case CALL(tuple_=false, builtin=true,
            path=IDENT(name="String"),
            expLst={s, minlen, leftjust}) then
    let tvar = tempDecl("modelica_string", &varDecls /*BUFD*/)
    let sExp = daeExp(s, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let minlenExp = daeExp(minlen, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let leftjustExp = daeExp(leftjust, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let typeStr = expTypeFromExpModelica(s)
    let &preExp += '<%tvar%> = <%typeStr%>_to_modelica_string(<%sExp%>, <%minlenExp%>, <%leftjustExp%>);<%\n%>'
    '<%tvar%>'
  
  case CALL(tuple_=false, builtin=true,
            path=IDENT(name="String"),
            expLst={s, minlen, leftjust, signdig}) then
    let tvar = tempDecl("modelica_string", &varDecls /*BUFD*/)
    let sExp = daeExp(s, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let minlenExp = daeExp(minlen, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let leftjustExp = daeExp(leftjust, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let signdigExp = daeExp(signdig, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let &preExp += '<%tvar%> = modelica_real_to_modelica_string(<%sExp%>, <%minlenExp%>, <%leftjustExp%>, <%signdigExp%>);<%\n%>'
    '<%tvar%>'
  
  case CALL(tuple_=false, builtin=true,
            path=IDENT(name="delay"),
            expLst={ICONST(integer=index), e, d, delayMax}) then
    let tvar = tempDecl("modelica_real", &varDecls /*BUFD*/)
    let var1 = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let var2 = daeExp(d, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let var3 = daeExp(delayMax, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let &preExp += '<%tvar%> = delayImpl(<%index%>, <%var1%>, time, <%var2%>, <%var3%>);<%\n%>'
    '<%tvar%>'
  
  case CALL(tuple_=false, builtin=true,
            path=IDENT(name="integer"),
            expLst={toBeCasted}) then
    let castedVar = daeExp(toBeCasted, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    '((modelica_integer)<%castedVar%>)'
  
  case CALL(tuple_=false, builtin=true,
            path=IDENT(name="Integer"),
            expLst={toBeCasted}) then
    let castedVar = daeExp(toBeCasted, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    '((modelica_integer)<%castedVar%>)'
  
  case CALL(tuple_=false, builtin=true, path=IDENT(name="clock"), expLst={}) then
    'mmc_clock()'

  case CALL(tuple_=false, builtin=true,
            path=IDENT(name="noEvent"),
            expLst={e1}) then
    daeExp(e1, context, &preExp, &varDecls)
  
  case CALL(tuple_=false, builtin=true,
            path=IDENT(name="anyString"),
            expLst={e1}) then
    'mmc_anyString(<%daeExp(e1, context, &preExp, &varDecls)%>)'
  
  case CALL(tuple_=false, builtin=true,
            path=IDENT(name="mmc_get_field"),
            expLst={s1, ICONST(integer=i)}) then
    let tvar = tempDecl("modelica_metatype", &varDecls /*BUFD*/)
    let expPart = daeExp(s1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let &preExp += '<%tvar%> = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(<%expPart%>), <%i%>));<%\n%>'
    '<%tvar%>'
  
  case CALL(tuple_=false, builtin=true, path=IDENT(name = "mmc_unbox_record"),
            expLst={s1}, ty=ty) then
    let argStr = daeExp(s1, context, &preExp, &varDecls)
    unboxRecord(argStr, ty, &preExp, &varDecls)
  
  case exp as CALL(__) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let retType = '<%funName%>_rettype'
    let retVar = match exp
      case CALL(ty=ET_NORETCALL(__)) then ""
      else tempDecl(retType, &varDecls)
    let &preExp += if not builtin then match context case SIMULATION(__) case SIMULATION2(__) then 'SIM_PROF_TICK_FN(<%funName%>_index);<%\n%>'
    let &preExp += '<%if retVar then '<%retVar%> = '%><%daeExpCallBuiltinPrefix(builtin)%><%funName%>(<%argStr%>);<%\n%>'
    let &preExp += if not builtin then match context case SIMULATION(__) case SIMULATION2(__) then 'SIM_PROF_ACC_FN(<%funName%>_index);<%\n%>'
    match exp
      // no return calls
      case CALL(ty=ET_NORETCALL(__)) then '/* NORETCALL */'
      // non tuple calls (single return value)
      case CALL(tuple_=false) then
        if builtin then '<%retVar%>' else '<%retVar%>.<%retType%>_1'
      // tuple calls (multiple return values)
      case CALL(tuple_=true) then
        '<%retVar%>'
end daeExpCall;


template daeExpCallBuiltinPrefix(Boolean builtin)
 "Helper to daeExpCall."
::=
  match builtin
  case true  then ""
  case false then "_"
end daeExpCallBuiltinPrefix;


template daeExpArray(Exp exp, Context context, Text &preExp /*BUFP*/,
                     Text &varDecls /*BUFP*/)
 "Generates code for an array expression."
::=
match exp
case ARRAY(__) then
  let arrayTypeStr = expTypeArray(ty)
  let arrayVar = tempDecl(arrayTypeStr, &varDecls /*BUFD*/)
  let scalarPrefix = if scalar then "scalar_" else ""
  let scalarRef = if scalar then "&" else ""
  let params = (array |> e =>
      let prefix = if scalar then '(<%expTypeFromExpModelica(e)%>)' else '&'
      '<%prefix%><%daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)%>'
    ;separator=", ")
  let &preExp += 'array_alloc_<%scalarPrefix%><%arrayTypeStr%>(&<%arrayVar%>, <%listLength(array)%>, <%params%>);<%\n%>'
  arrayVar
end daeExpArray;


template daeExpMatrix(Exp exp, Context context, Text &preExp /*BUFP*/,
                      Text &varDecls /*BUFP*/)
 "Generates code for a matrix expression."
::=
  match exp
  case MATRIX(scalar={{}})  // special case for empty matrix: create dimensional array Real[0,1]
  case MATRIX(scalar={})    // special case for empty array: create dimensional array Real[0,1] 
    then    
    let arrayTypeStr = expTypeArray(ty)
    let tmp = tempDecl(arrayTypeStr, &varDecls /*BUFD*/)
    let &preExp += 'alloc_<%arrayTypeStr%>(&<%tmp%>, 2, 0, 1);<%\n%>'
    tmp
  case m as MATRIX(__) then
    let arrayTypeStr = expTypeArray(m.ty)
    let &vars2 = buffer "" /*BUFD*/
    let &promote = buffer "" /*BUFD*/
    let catAlloc = (m.scalar |> row =>
        let tmp = tempDecl(arrayTypeStr, &varDecls /*BUFD*/)
        let vars = daeExpMatrixRow(row, arrayTypeStr, context,
                                 &promote /*BUFC*/, &varDecls /*BUFD*/)
        let &vars2 += ', &<%tmp%>'
        'cat_alloc_<%arrayTypeStr%>(2, &<%tmp%>, <%listLength(row)%><%vars%>);'
      ;separator="\n")
    let &preExp += promote
    let &preExp += catAlloc
    let &preExp += "\n"
    let tmp = tempDecl(arrayTypeStr, &varDecls /*BUFD*/)
    let &preExp += 'cat_alloc_<%arrayTypeStr%>(1, &<%tmp%>, <%listLength(m.scalar)%><%vars2%>);<%\n%>'
    tmp
end daeExpMatrix;


template daeExpMatrixRow(list<tuple<Exp,Boolean>> row, String arrayTypeStr,
                         Context context, Text &preExp /*BUFP*/,
                         Text &varDecls /*BUFP*/)
 "Helper to daeExpMatrix."
::=
  let &varLstStr = buffer "" /*BUFD*/
  let preExp2 = (row |> col as (e, b) =>
      let scalarStr = if b then "scalar_" else ""
      let scalarRefStr = if b then "" else "&"
      let expVar = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
      let tmp = tempDecl(arrayTypeStr, &varDecls /*BUFD*/)
      let &varLstStr += ', &<%tmp%>'
      'promote_<%scalarStr%><%arrayTypeStr%>(<%scalarRefStr%><%expVar%>, 2, &<%tmp%>);'
    ;separator="\n")
  let &preExp2 += "\n"
  let &preExp += preExp2
  varLstStr
end daeExpMatrixRow;


template daeExpCast(Exp exp, Context context, Text &preExp /*BUFP*/,
                    Text &varDecls /*BUFP*/)
 "Generates code for a cast expression."
::=
match exp
case CAST(__) then
  let expVar = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  match ty
  case ET_INT(__)   then '((modelica_integer)<%expVar%>)'  
  case ET_REAL(__)  then '((modelica_real)<%expVar%>)'
  case ET_ENUMERATION(__)   then '((modelica_integer)<%expVar%>)'
  case ET_BOOL(__)   then '((modelica_boolean)<%expVar%>)'  
  case ET_ARRAY(__) then
    let arrayTypeStr = expTypeArray(ty)
    let tvar = tempDecl(arrayTypeStr, &varDecls /*BUFD*/)
    let to = expTypeShort(ty)
    let from = expTypeFromExpShort(exp)
    let &preExp += 'cast_<%from%>_array_to_<%to%>(&<%expVar%>, &<%tvar%>);<%\n%>'
    '<%tvar%>'
  else 
    '(<%expVar%>) /* could not cast, using the variable as it is */'
end daeExpCast;


template daeExpAsub(Exp exp, Context context, Text &preExp /*BUFP*/,
                    Text &varDecls /*BUFP*/)
 "Generates code for an asub expression."
::=
  match expTypeFromExpShort(exp)
  case "metatype" then
  // MetaModelica Array
    (match exp case ASUB(exp=e, sub={idx}) then
      let e1 = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
      let idx1 = daeExp(idx, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
      'arrayGet(<%e1%>,<%idx1%>) /* DAE.ASUB */')
  // Modelica Array
  else
  match exp
  
  case ASUB(exp=RANGE(ty=t), sub={idx}) then
    'ASUB_EASY_CASE'
  
  case ASUB(exp=ASUB(
              exp=ASUB(
                exp=ASUB(exp=e, sub={ICONST(integer=i)}),
                sub={ICONST(integer=j)}),
              sub={ICONST(integer=k)}),
            sub={ICONST(integer=l)}) then
    let e1 = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let typeShort = expTypeFromExpShort(e)
    '<%typeShort%>_get_4D(&<%e1%>, <%incrementInt(i,-1)%>, <%incrementInt(j,-1)%>, <%incrementInt(k,-1)%>, <%incrementInt(l,-1)%>)'            
  
  case ASUB(exp=ASUB(
              exp=ASUB(exp=e, sub={ICONST(integer=i)}),
              sub={ICONST(integer=j)}),
            sub={ICONST(integer=k)}) then
    let e1 = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let typeShort = expTypeFromExpShort(e)
    '<%typeShort%>_get_3D(&<%e1%>, <%incrementInt(i,-1)%>, <%incrementInt(j,-1)%>, <%incrementInt(k,-1)%>)'            
  
  case ASUB(exp=ASUB(exp=e, sub={ICONST(integer=i)}),
            sub={ICONST(integer=j)}) then
    let e1 = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let typeShort = expTypeFromExpShort(e)
    '<%typeShort%>_get_2D(&<%e1%>, <%incrementInt(i,-1)%>, <%incrementInt(j,-1)%>)'            
  
  case ASUB(exp=e, sub={ICONST(integer=i)}) then
    let e1 = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let typeShort = expTypeFromExpShort(e)
    '<%typeShort%>_get(&<%e1%>, <%incrementInt(i,-1)%>)'
  
  case ASUB(exp=ecr as CREF(__), sub=subs) then
    let arrName = daeExpCrefRhs(buildCrefExpFromAsub(ecr, subs), context,
                              &preExp /*BUFC*/, &varDecls /*BUFD*/)
    match context case FUNCTION_CONTEXT(__)  then
      arrName
    else
      arrayScalarRhs(ecr.ty, subs, arrName, context, &preExp, &varDecls)
  
  case ASUB(exp=ASUB(
              exp=ASUB(
                exp=ASUB(exp=e, sub={ENUM_LITERAL(index=i)}),
                sub={ENUM_LITERAL(index=j)}),
              sub={ENUM_LITERAL(index=k)}),
            sub={ENUM_LITERAL(index=l)}) then
    let e1 = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let typeShort = expTypeFromExpShort(e)
    '<%typeShort%>_get_4D(&<%e1%>, <%incrementInt(i,-1)%>, <%incrementInt(j,-1)%>, <%incrementInt(k,-1)%>, <%incrementInt(l,-1)%>)'            
  
  case ASUB(exp=ASUB(
              exp=ASUB(exp=e, sub={ENUM_LITERAL(index=i)}),
              sub={ENUM_LITERAL(index=j)}),
            sub={ENUM_LITERAL(index=k)}) then
    let e1 = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let typeShort = expTypeFromExpShort(e)
    '<%typeShort%>_get_3D(&<%e1%>, <%incrementInt(i,-1)%>, <%incrementInt(j,-1)%>, <%incrementInt(k,-1)%>)'            
  
  case ASUB(exp=ASUB(exp=e, sub={ENUM_LITERAL(index=i)}),
            sub={ENUM_LITERAL(index=j)}) then
    let e1 = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let typeShort = expTypeFromExpShort(e)
    '<%typeShort%>_get_2D(&<%e1%>, <%incrementInt(i,-1)%>, <%incrementInt(j,-1)%>)'
  
  case ASUB(exp=e, sub={ENUM_LITERAL(index=i)}) then
    let e1 = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let typeShort = expTypeFromExpShort(e)
    '<%typeShort%>_get(&<%e1%>, <%incrementInt(i,-1)%>)'
  
  case ASUB(exp=e, sub={index}) then
    let exp = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let expIndex = daeExp(index, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let typeShort = expTypeFromExpShort(e)
    '<%typeShort%>_get(&<%exp%>, ((<%expIndex%>) - 1))'
  
  case ASUB(exp=e, sub=indexes) then
    let exp = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let expIndexes = (indexes |> index => '<%daeExp(index, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)%>' ;separator=", ")
    'CODEGEN_COULD_NOT_HANDLE_ASUB(<%exp%>[<%expIndexes%>])'
  
  else
    'OTHER_ASUB'
end daeExpAsub;


template daeExpSize(Exp exp, Context context, Text &preExp /*BUFP*/,
                    Text &varDecls /*BUFP*/)
 "Generates code for a size expression."
::=
  match exp
  case SIZE(exp=CREF(__), sz=SOME(dim)) then
    let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let dimPart = daeExp(dim, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let resVar = tempDecl("modelica_integer", &varDecls /*BUFD*/)
    let typeStr = '<%expTypeArray(exp.ty)%>'
    let &preExp += '<%resVar%> = size_of_dimension_<%typeStr%>(<%expPart%>, <%dimPart%>);<%\n%>'
    resVar
  else "size(X) not implemented"
end daeExpSize;


template daeExpReduction(Exp exp, Context context, Text &preExp /*BUFP*/,
                         Text &varDecls /*BUFP*/)
 "Generates code for a reduction expression."
::=
match exp
case REDUCTION(path = IDENT(name = op)) then
  let identType = expTypeFromExpModelica(expr)
  let accFun = daeExpReductionFnName(op, identType)
  let startValue = daeExpReductionStartValue(op, identType)
  let res = tempDecl(identType, &varDecls)
  let &tmpExpPre = buffer ""
  let tmpExpVar = daeExp(expr, context, &tmpExpPre, &varDecls)
  let cast = match accFun case "max" then "(modelica_real)"
                          case "min" then "(modelica_real)"
                          else ""
  let body =
    <<
    <%tmpExpPre%>
    <%res%> = <%accFun%>(<%cast%>(<%res%>), <%cast%>(<%tmpExpVar%>));
    >>
  let &preExp +=
    <<
    <%res%> = <%startValue%>;
    <%daeExpReductionLoop(exp, body, context, &varDecls)%>
    >>
  res
end daeExpReduction;

template daeExpReductionLoop(Exp exp, Text &body, Context context, Text &varDecls)
 "Generates code for the loop part of a reduction expression by using the
  appropriate for loop template."
::=
match exp
case REDUCTION(range = RANGE(__)) then
  let identType = expTypeModelica(range.ty)
  let identTypeShort = expTypeFromExpShort(expr)
  algStmtForRange_impl(range, ident, identType, identTypeShort, body, context, &varDecls)
case REDUCTION(range = range) then
  let identType = expTypeFromExpModelica(expr)
  let arrayType = expTypeFromExpArray(expr)
  algStmtForGeneric_impl(range, ident, identType, arrayType, false, body, context, &varDecls)
end daeExpReductionLoop;
  

template daeExpReductionFnName(String reduction_op, String type)
 "Helper to daeExpReduction."
::=
  match reduction_op
  case "sum" then
    match type
    case "modelica_integer" then "reduction_sum"
    case "modelica_real" then "reduction_sum"
    else "INVALID_TYPE"
    end match
  case "product" then
    match type
    case "modelica_integer" then "reduction_product"
    case "modelica_real" then "reduction_product"
    else "INVALID_TYPE"
    end match  
  else reduction_op
end daeExpReductionFnName;


template daeExpReductionStartValue(String reduction_op, String type)
 "Helper to daeExpReduction."
::=
  match reduction_op
  case "min" then
    match type
    case "modelica_integer" then "LONG_MAX"
    case "modelica_real" then "DBL_MAX"
    else "INVALID_TYPE"
    end match
  case "max" then 
    match type

    case "modelica_integer" then "LONG_MIN"
    case "modelica_real" then "DBL_MIN"
    else "INVALID_TYPE"
    end match
  case "sum" then "0"
  case "product" then "1"
  else "UNKNOWN_REDUCTION"
end daeExpReductionStartValue;

template daeExpMatch(Exp exp, Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Generates code for a match expression."
::=
match exp
case exp as MATCHEXPRESSION(__) then
  let res = match et case ET_NORETCALL(__) then "ERROR_MATCH_EXPRESSION_NORETCALL" else tempDecl(expTypeModelica(et), &varDecls)
  daeExpMatch2(exp,listExpLength1,res,context,&preExp,&varDecls)
end daeExpMatch;

template daeExpMatch2(Exp exp, list<Exp> tupleAssignExps, Text res, Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Generates code for a match expression."
::=
match exp
case exp as MATCHEXPRESSION(__) then
  let &preExpInner = buffer ""
  let &preExpRes = buffer ""
  let &varDeclsInput = buffer ""
  let &varDeclsInner = buffer ""
  let &ignore = buffer ""
  let ignore2 = (elementVars(localDecls) |> var =>
      varInit(var, "", 0, &varDeclsInner /*BUFC*/, &preExpInner /*BUFC*/)
    )
  let prefix = 'tmp<%System.tmpTick()%>'
  let &preExpInput = buffer ""
  let &expInput = buffer ""
  let ignore3 = (inputs |> exp hasindex i0 =>
    let decl = '<%prefix%>_in<%i0%>'
    let &varDeclsInput += '<%expTypeFromExpModelica(exp)%> <%decl%>;<%\n%>'
    let &expInput += '<%decl%> = <%daeExp(exp, context, &preExpInput, &varDeclsInput)%>;<%\n%>'
    ""; empty)
  let ix = match exp.matchType
    case MATCH(switch=SOME((switchIndex,ET_STRING(__),div))) then
      'stringHashDjb2Mod(<%prefix%>_in<%switchIndex%>,<%div%>)'
    case MATCH(switch=SOME((switchIndex,ET_METATYPE(__),_))) then
      'valueConstructor(<%prefix%>_in<%switchIndex%>)'
    case MATCH(switch=SOME((switchIndex,ty as ET_INT(__),_))) then
      '<%prefix%>_in<%switchIndex%>'
    case MATCH(switch=SOME(_)) then
      '<%\n%>#error "unknown switch"<%\n%>'
    else tempDecl('int', &varDeclsInner)
  let done = tempDecl('int', &varDeclsInner)
  let onPatternFail = match exp.matchType case MATCHCONTINUE(__) then "MMC_THROW()" case MATCH(__) then "break"
  let &preExp +=
      <<
      { /* <% match exp.matchType case MATCHCONTINUE(__) then "matchcontinue expression" case MATCH(__) then "match expression" %> */
        <%varDeclsInput%>
        <%preExpInput%>
        <%expInput%>
        {
          <%varDeclsInner%>
          <%preExpInner%>
          <%match exp.matchType
          case MATCH(switch=SOME(_)) then '<%done%> = 0;<%\n%>{'
          else 'for (<%ix%> = 0, <%done%> = 0; <%ix%> < <%listLength(exp.cases)%> && !<%done%>; <%ix%>++) {'
          %>
            <% match exp.matchType case MATCHCONTINUE(__) then "MMC_TRY()" %>
            switch (<%ix%>) {
            <%daeExpMatchCases(exp.cases,tupleAssignExps,exp.matchType,ix,res,prefix,onPatternFail,done,context,&varDecls)%>
            }
            <% match exp.matchType case MATCHCONTINUE(__) then "MMC_CATCH()" %>
          }
          if (!<%done%>) MMC_THROW();
        }
      }
      >>
  res
end daeExpMatch2;

template daeExpMatchCases(list<MatchCase> cases, list<Exp> tupleAssignExps, DAE.MatchType ty, Text ix, Text res, Text prefix, Text onPatternFail, Text done, Context context, Text &varDecls)
::=
  cases |> c as CASE(__) hasindex i0 =>
  let &varDeclsCaseInner = buffer ""
  let &preExpCaseInner = buffer ""
  let &assignments = buffer ""
  let &preRes = buffer ""
  let patternMatching = (c.patterns |> lhs hasindex i0 => patternMatch(lhs,'<%prefix%>_in<%i0%>',onPatternFail,&varDeclsCaseInner,&assignments); empty)
  let stmts = (c.body |> stmt => algStatement(stmt, context, &varDeclsCaseInner); separator="\n")
  let caseRes = (match c.result
    case SOME(TUPLE(PR=exps)) then
      (exps |> e hasindex i1 from 1 => '<%res%>_targ<%i1%> = <%daeExp(e,context,&preRes,&varDeclsCaseInner)%>;<%\n%>')
    case SOME(exp as CALL(tuple_=true)) then
      let retStruct = daeExp(exp, context, &preRes, &varDeclsCaseInner)
      (tupleAssignExps |> cr hasindex i1 from 1 =>
        '<%res%>_targ<%i1%> = <%retStruct%>.targ<%i1%>;<%\n%>')
    case SOME(e) then '<%res%> = <%daeExp(e,context,&preRes,&varDeclsCaseInner)%>;<%\n%>')
  let _ = (elementVars(c.localDecls) |> var => varInit(var, "", 0, &varDeclsCaseInner, &preExpCaseInner))
  <<<%match ty case MATCH(switch=SOME((n,_,ea))) then switchIndex(listNth(c.patterns,n),ea) else 'case <%i0%>'%>: {
    <%varDeclsCaseInner%>
    <%preExpCaseInner%>
    <%patternMatching%> 
    <% match c.jump
       case 0 then "/* Pattern matching succeeded */"
       else '<%ix%> += <%c.jump%>; /* Pattern matching succeeded; we may skip some cases if we fail */'
    %>
    <%assignments%>
    <%stmts%>
    /*#modelicaLine <%infoStr(c.resultInfo)%>*/
    <% if c.result then '<%preRes%><%caseRes%>' else 'MMC_THROW();<%\n%>' %>
    /*#endModelicaLine*/
    <%done%> = 1;
    break;
  }<%\n%>
  >>
end daeExpMatchCases;

template switchIndex(Pattern pattern, Integer extraArg)
::=
  match pattern
    case PAT_CALL(__) then 'case <%getValueCtor(index)%>'
    case PAT_CONSTANT(exp=e as SCONST(__)) then 'case <%stringHashDjb2Mod(e.string,extraArg)%> /* <%e.string%> */'
    case PAT_CONSTANT(exp=e as ICONST(__)) then 'case <%e.integer%>'
    else 'default'
end switchIndex;

template daeExpBox(Exp exp, Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Generates code for a match expression."
::=
match exp
case exp as BOX(__) then
  let ty = expTypeFromExpShort(exp.exp)
  let res = daeExp(exp.exp,context,&preExp,&varDecls)
  'mmc_mk_<%ty%>(<%res%>)'
end daeExpBox;

template daeExpUnbox(Exp exp, Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Generates code for a match expression."
::=
match exp
case exp as UNBOX(__) then
  let ty = expTypeShort(exp.ty)
  let res = daeExp(exp.exp,context,&preExp,&varDecls)
  'mmc_unbox_<%ty%>(<%res%>) /* DAE.UNBOX */'
end daeExpUnbox;

template daeExpSharedLiteral(Exp exp, Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Generates code for a match expression."
::=
match exp case exp as SHARED_LITERAL(__) then '_OMC_LIT<%exp.index%>'
end daeExpSharedLiteral;


// TODO: Optimize as in Codegen
// TODO: Use this function in other places where almost the same thing is hard
//       coded
template arrayScalarRhs(ExpType ty, list<Exp> subs, String arrName, Context context,
               Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Helper to daeExpAsub."
::=
  let arrayType = expTypeArray(ty)
  let dimsLenStr = listLength(subs)
  let dimsValuesStr = (subs |> exp =>
      daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    ;separator=", ")
  match arrayType
    case "metatype_array" then
      'arrayGet(<%arrName%>,<%dimsValuesStr%>) /*arrayScalarRhs*/'
    else
      <<
      (*<%arrayType%>_element_addr(&<%arrName%>, <%dimsLenStr%>, <%dimsValuesStr%>))
      >>
end arrayScalarRhs;

template daeExpList(Exp exp, Context context, Text &preExp /*BUFP*/,
                    Text &varDecls /*BUFP*/)
 "Generates code for a meta modelica list expression."
::=
match exp
case LIST(__) then
  let tmp = tempDecl("modelica_metatype", &varDecls /*BUFD*/)
  let expPart = daeExpListToCons(valList, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  let &preExp += '<%tmp%> = <%expPart%>;<%\n%>'
  tmp
end daeExpList;


template daeExpListToCons(list<Exp> listItems, Context context, Text &preExp /*BUFP*/,
                          Text &varDecls /*BUFP*/)
 "Helper to daeExpList."
::=
  match listItems
  case {} then "MMC_REFSTRUCTLIT(mmc_nil)"
  case e :: rest then
    let expPart = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let restList = daeExpListToCons(rest, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    <<
    mmc_mk_cons(<%expPart%>, <%restList%>)
    >>
end daeExpListToCons;


template daeExpCons(Exp exp, Context context, Text &preExp /*BUFP*/,
                    Text &varDecls /*BUFP*/)
 "Generates code for a meta modelica cons expression."
::=
match exp
case CONS(__) then
  let tmp = tempDecl("modelica_metatype", &varDecls /*BUFD*/)
  let carExp = daeExp(car, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  let cdrExp = daeExp(cdr, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  let &preExp += '<%tmp%> = mmc_mk_cons(<%carExp%>, <%cdrExp%>);<%\n%>'
  tmp
end daeExpCons;


template daeExpMetaTuple(Exp exp, Context context, Text &preExp /*BUFP*/,
                         Text &varDecls /*BUFP*/)
 "Generates code for a meta modelica tuple expression."
::=
match exp
case META_TUPLE(__) then
  let start = daeExpMetaHelperBoxStart(listLength(listExp))
  let args = (listExp |> e => daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    ;separator=", ")
  let tmp = tempDecl("modelica_metatype", &varDecls /*BUFD*/)
  let &preExp += '<%tmp%> = mmc_mk_box<%start%>0<%if args then ", "%><%args%>);<%\n%>'
  tmp
end daeExpMetaTuple;


template daeExpMetaOption(Exp exp, Context context, Text &preExp /*BUFP*/,
                          Text &varDecls /*BUFP*/)
 "Generates code for a meta modelica option expression."
::=
  match exp
  case META_OPTION(exp=NONE()) then
    "mmc_mk_none()"
  case META_OPTION(exp=SOME(e)) then
    let expPart = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    'mmc_mk_some(<%expPart%>)'
end daeExpMetaOption;


template daeExpMetarecordcall(Exp exp, Context context, Text &preExp /*BUFP*/,
                              Text &varDecls /*BUFP*/)
 "Generates code for a meta modelica record call expression."
::=
match exp
case METARECORDCALL(__) then
  let newIndex = getValueCtor(index)
  let argsStr = if args then
      ', <%args |> exp =>
        daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
      ;separator=", "%>'
    else
      ""
  let box = 'mmc_mk_box<%daeExpMetaHelperBoxStart(incrementInt(listLength(args), 1))%><%newIndex%>, &<%underscorePath(path)%>__desc<%argsStr%>)'
  let tmp = tempDecl("modelica_metatype", &varDecls /*BUFD*/)
  let &preExp += '<%tmp%> = <%box%>;<%\n%>'
  tmp
end daeExpMetarecordcall;

template daeExpMetaHelperBoxStart(Integer numVariables)
 "Helper to determine how mmc_mk_box should be called."
::=
  match numVariables
  case 0
  case 1
  case 2
  case 3
  case 4
  case 5
  case 6
  case 7
  case 8
  case 9 then '<%numVariables%>('
  else '(<%numVariables%>, '
end daeExpMetaHelperBoxStart;

template outDecl(String ty, Text &varDecls /*BUFP*/)
 "Declares a temporary variable in varDecls and returns the name."
::=
  let newVar = 'out'
  let &varDecls += '<%ty%> <%newVar%>;<%\n%>'
  newVar
end outDecl;

template tempDecl(String ty, Text &varDecls /*BUFP*/)
 "Declares a temporary variable in varDecls and returns the name."
::=
  let newVar = 'tmp<%System.tmpTick()%>'
  let &varDecls += '<%ty%> <%newVar%>;<%\n%>'
  newVar
end tempDecl;

template tempDeclConst(String ty, String val, Text &varDecls /*BUFP*/)
 "Declares a temporary variable in varDecls and returns the name."
::=
  let newVar = 'tmp<%System.tmpTick()%>'
  let &varDecls += '<%ty%> <%newVar%> = <%val%>;<%\n%>'
  newVar
end tempDeclConst;

template varType(Variable var)
 "Generates type for a variable."
::=
match var
case var as VARIABLE(__) then
  if instDims then
    expTypeArray(var.ty)
  else
    expTypeArrayIf(var.ty)
end varType;

template varTypeBoxed(Variable var)
::=
match var
case VARIABLE(__) then 'modelica_metatype'
case FUNCTION_PTR(__) then 'modelica_fnptr'
end varTypeBoxed;

template expTypeRW(DAE.ExpType type)
 "Helper to writeOutVarRecordMembers."
::=
  match type
  case ET_INT(__)         then "TYPE_DESC_INT"
  case ET_REAL(__)        then "TYPE_DESC_REAL"
  case ET_STRING(__)      then "TYPE_DESC_STRING"
  case ET_BOOL(__)        then "TYPE_DESC_BOOL"
  case ET_ENUMERATION(__) then "TYPE_DESC_INT"  
  case ET_ARRAY(__)       then '<%expTypeRW(ty)%>_ARRAY'
  case ET_COMPLEX(complexClassType=RECORD(__))
                      then "TYPE_DESC_RECORD"
  case ET_METATYPE(__) case ET_BOXED(__)    then "TYPE_DESC_MMC"
end expTypeRW;

template expTypeShort(DAE.ExpType type)
 "Generate type helper."
::=
  match type
  case ET_INT(__)         then "integer"  
  case ET_REAL(__)        then "real"
  case ET_STRING(__)      then if acceptMetaModelicaGrammar() then "metatype" else "string"
  case ET_BOOL(__)        then "boolean"
  case ET_ENUMERATION(__) then "integer"  
  case ET_OTHER(__)       then "complex"
  case ET_ARRAY(__)       then expTypeShort(ty)   
  case ET_COMPLEX(complexClassType=EXTERNAL_OBJ(__))
                      then "complex"
  case ET_COMPLEX(__)     then 'struct <%underscorePath(name)%>'  
  case ET_METATYPE(__) case ET_BOXED(__)    then "metatype"
  case ET_FUNCTION_REFERENCE_VAR(__) then "fnptr"
  else "expTypeShort:ERROR"
end expTypeShort;

template mmcVarType(Variable var)
::=
  match var
  case VARIABLE(__) then 'modelica_<%mmcExpTypeShort(ty)%>'
  case FUNCTION_PTR(__) then 'modelica_fnptr'
end mmcVarType;

template mmcExpTypeShort(DAE.ExpType type)
::=
  match type
  case ET_INT(__)                     then "integer"
  case ET_REAL(__)                    then "real"
  case ET_STRING(__)                  then "string"
  case ET_BOOL(__)                    then "integer"
  case ET_ENUMERATION(__)             then "integer"
  case ET_ARRAY(__)                   then "array"
  case ET_METATYPE(__) case ET_BOXED(__)                then "metatype"
  case ET_FUNCTION_REFERENCE_VAR(__)  then "fnptr"
  else "mmcExpTypeShort:ERROR"
end mmcExpTypeShort;

template expType(DAE.ExpType ty, Boolean array)
 "Generate type helper."
::=
  match array
  case true  then expTypeArray(ty)
  case false then expTypeModelica(ty)
end expType;


template expTypeModelica(DAE.ExpType ty)
 "Generate type helper."
::=
  expTypeFlag(ty, 2)
end expTypeModelica;


template expTypeArray(DAE.ExpType ty)
 "Generate type helper."
::=
  expTypeFlag(ty, 3)
end expTypeArray;


template expTypeArrayIf(DAE.ExpType ty)
 "Generate type helper."
::=
  expTypeFlag(ty, 4)
end expTypeArrayIf;


template expTypeFromExpShort(Exp exp)
 "Generate type helper."
::=
  expTypeFromExpFlag(exp, 1)
end expTypeFromExpShort;


template expTypeFromExpModelica(Exp exp)
 "Generate type helper."
::=
  expTypeFromExpFlag(exp, 2)
end expTypeFromExpModelica;


template expTypeFromExpArray(Exp exp)
 "Generate type helper."
::=
  expTypeFromExpFlag(exp, 3)
end expTypeFromExpArray;


template expTypeFromExpArrayIf(Exp exp)
 "Generate type helper."
::=
  expTypeFromExpFlag(exp, 4)
end expTypeFromExpArrayIf;


template expTypeFlag(DAE.ExpType ty, Integer flag)
 "Generate type helper."
::=
  match flag
  case 1 then
    // we want the short type
    expTypeShort(ty)
  case 2 then
    // we want the "modelica type"
    match ty case ET_COMPLEX(complexClassType=EXTERNAL_OBJ(__)) then
      'modelica_<%expTypeShort(ty)%>'
    else match ty case ET_COMPLEX(__) then
      'struct <%underscorePath(name)%>'
    else
      'modelica_<%expTypeShort(ty)%>'
  case 3 then
    // we want the "array type"
    '<%expTypeShort(ty)%>_array'
  case 4 then
    // we want the "array type" only if type is array, otherwise "modelica type"
    match ty
    case ET_ARRAY(__) then '<%expTypeShort(ty)%>_array'
    else expTypeFlag(ty, 2)
end expTypeFlag;



template expTypeFromExpFlag(Exp exp, Integer flag)
 "Generate type helper."
::=
  match exp
  case ICONST(__)        then match flag case 8 then "int" case 1 then "integer" else "modelica_integer"
  case RCONST(__)        then match flag case 1 then "real" else "modelica_real"
  case SCONST(__)        then if acceptMetaModelicaGrammar() then
                                (match flag case 1 then "metatype" else "modelica_metatype")
                              else
                                (match flag case 1 then "string" else "modelica_string")
  case BCONST(__)        then match flag case 1 then "boolean" else "modelica_boolean"
  case ENUM_LITERAL(__)  then match flag case 8 then "int" case 1 then "integer" else "modelica_integer"
  case e as BINARY(__)
  case e as UNARY(__)
  case e as LBINARY(__)
  case e as LUNARY(__)
  case e as RELATION(__) then expTypeFromOpFlag(e.operator, flag)
  case IFEXP(__)         then expTypeFromExpFlag(expThen, flag)
  case CALL(__)          then expTypeFlag(ty, flag)
  case c as ARRAY(__)
  case c as MATRIX(__)
  case c as RANGE(__)
  case c as CAST(__)
  case c as CREF(__)
  case c as CODE(__)     then expTypeFlag(c.ty, flag)
  case ASUB(__)          then expTypeFromExpFlag(exp, flag)
  case REDUCTION(__)     then expTypeFromExpFlag(expr, flag)
  case BOX(__)
  case CONS(__)
  case LIST(__)

  case META_TUPLE(__)
  case META_OPTION(__)
  case MATCHEXPRESSION(__)
  case METARECORDCALL(__)
  case BOX(__)           then match flag case 1 then "metatype" else "modelica_metatype"
  case c as UNBOX(__)    then expTypeFlag(c.ty, flag)
  case c as SHARED_LITERAL(__) then expTypeFlag(c.ty, flag)
  else '#error "expTypeFromExpFlag:<%printExpStr(exp)%>"'
end expTypeFromExpFlag;


template expTypeFromOpFlag(Operator op, Integer flag)
 "Generate type helper."
::=
  match op
  case o as ADD(__)
  case o as SUB(__)
  case o as MUL(__)
  case o as DIV(__)
  case o as POW(__)

  case o as UMINUS(__)
  case o as UPLUS(__)
  case o as UMINUS_ARR(__)
  case o as UPLUS_ARR(__)
  case o as ADD_ARR(__)
  case o as SUB_ARR(__)
  case o as MUL_ARR(__)
  case o as DIV_ARR(__)
  case o as MUL_SCALAR_ARRAY(__)
  case o as MUL_ARRAY_SCALAR(__)
  case o as ADD_SCALAR_ARRAY(__)
  case o as ADD_ARRAY_SCALAR(__)
  case o as SUB_SCALAR_ARRAY(__)
  case o as SUB_ARRAY_SCALAR(__)
  case o as MUL_SCALAR_PRODUCT(__)
  case o as MUL_MATRIX_PRODUCT(__)
  case o as DIV_ARRAY_SCALAR(__)
  case o as DIV_SCALAR_ARRAY(__)
  case o as POW_ARRAY_SCALAR(__)
  case o as POW_SCALAR_ARRAY(__)
  case o as POW_ARR(__)
  case o as POW_ARR2(__)
  case o as LESS(__)
  case o as LESSEQ(__)
  case o as GREATER(__)
  case o as GREATEREQ(__)
  case o as EQUAL(__)
  case o as NEQUAL(__) then
    expTypeFlag(o.ty, flag)
  case o as AND(__)
  case o as OR(__)
  case o as NOT(__) then
    match flag case 1 then "boolean" else "modelica_boolean"
  else "expTypeFromOpFlag:ERROR"
end expTypeFromOpFlag;

template dimension(Dimension d)
::=
  match d
  case DAE.DIM_INTEGER(__) then integer
  case DAE.DIM_ENUM(__) then size
  case DAE.DIM_UNKNOWN(__) then ":"
  else "INVALID_DIMENSION"
end dimension;

template algStmtAssignPattern(DAE.Statement stmt, Context context, Text &varDecls)
 "Generates an assigment algorithm statement."
::=
  match stmt
  case s as STMT_ASSIGN(exp1=lhs as PATTERN(__)) then
    let &preExp = buffer ""
    let &assignments = buffer ""
    let expPart = daeExp(s.exp, context, &preExp, &varDecls)
    <<<%preExp%>
    <%patternMatch(lhs.pattern,expPart,"MMC_THROW()",&varDecls,&assignments)%><%assignments%>>>
end algStmtAssignPattern;

template patternMatch(Pattern pat, Text rhs, Text onPatternFail, Text &varDecls, Text &assignments)
::=
  match pat
  case PAT_WILD(__) then ""
  case p as PAT_CONSTANT(__)
    then
      let &unboxBuf = buffer ""
      let urhs = (match p.ty
        case SOME(et) then unboxVariable(rhs, et, &unboxBuf, &varDecls)
        else rhs
      )
      <<<%unboxBuf%><%match p.exp
        case c as ICONST(__) then 'if (<%c.integer%> != <%urhs%>) <%onPatternFail%>;<%\n%>'
        case c as RCONST(__) then 'if (<%c.real%> != <%urhs%>) <%onPatternFail%>;<%\n%>'
        case c as SCONST(__) then
          let escstr = Util.escapeModelicaStringToCString(c.string)
          'if (<%unescapedStringLength(escstr)%> != MMC_STRLEN(<%urhs%>) || strcmp("<%escstr%>", MMC_STRINGDATA(<%urhs%>)) != 0) <%onPatternFail%>;<%\n%>'
        case c as BCONST(__) then 'if (<%c.bool%> != <%urhs%>) <%onPatternFail%>;<%\n%>'
        case c as LIST(valList = {}) then 'if (!listEmpty(<%urhs%>)) <%onPatternFail%>;<%\n%>'
        case c as META_OPTION(exp = NONE()) then 'if (!optionNone(<%urhs%>)) <%onPatternFail%>;<%\n%>'

        else 'UNKNOWN_CONSTANT_PATTERN'
      %>>>
  case p as PAT_SOME(__) then
    let tvar = tempDecl("modelica_metatype", &varDecls)
    <<if (optionNone(<%rhs%>)) <%onPatternFail%>;
    <%tvar%> = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(<%rhs%>), 1));
    <%patternMatch(p.pat,tvar,onPatternFail,&varDecls,&assignments)%>>>
  case PAT_CONS(__) then
    let tvarHead = tempDecl("modelica_metatype", &varDecls)
    let tvarTail = tempDecl("modelica_metatype", &varDecls)
    <<if (listEmpty(<%rhs%>)) <%onPatternFail%>;
    <%tvarHead%> = MMC_CAR(<%rhs%>);
    <%tvarTail%> = MMC_CDR(<%rhs%>);
    <%patternMatch(head,tvarHead,onPatternFail,&varDecls,&assignments)%><%patternMatch(tail,tvarTail,onPatternFail,&varDecls,&assignments)%>>>
  case PAT_META_TUPLE(__)
    then
      (patterns |> p hasindex i1 from 1 =>
        let tvar = tempDecl("modelica_metatype", &varDecls)
        <<<%tvar%> = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(<%rhs%>), <%i1%>));
        <%patternMatch(p,tvar,onPatternFail,&varDecls,&assignments)%>
        >>; empty /* increase the counter even if no output is produced */)
  case PAT_CALL_TUPLE(__)
    then
      (patterns |> p hasindex i1 from 1 =>
        let nrhs = '<%rhs%>.targ<%i1%>'
        patternMatch(p,nrhs,onPatternFail,&varDecls,&assignments)
        ; empty /* increase the counter even if no output is produced */
      )
  case PAT_CALL_NAMED(__)
    then
      <<<%patterns |> (p,n,t) =>
        let tvar = tempDecl(expTypeModelica(t), &varDecls)
        <<<%tvar%> = <%rhs%>.<%n%>;
        <%patternMatch(p,tvar,onPatternFail,&varDecls,&assignments)%>
        >>%>
      >>
  case PAT_CALL(__)
    then
      <<if (mmc__uniontype__metarecord__typedef__equal(<%rhs%>,<%index%>,<%listLength(patterns)%>) == 0) <%onPatternFail%>;
      <%(patterns |> p hasindex i2 from 2 =>
        let tvar = tempDecl("modelica_metatype", &varDecls)
        <<<%tvar%> = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(<%rhs%>), <%i2%>));
        <%patternMatch(p,tvar,onPatternFail,&varDecls,&assignments)%>
        >> ;empty) /* increase the counter even if no output is produced */
      %>
      >>
  case p as PAT_AS_FUNC_PTR(__) then
    let &assignments += '*((modelica_fnptr*)&_<%p.id%>) = <%rhs%>;<%\n%>'
    <<<%patternMatch(p.pat,rhs,onPatternFail,&varDecls,&assignments)%>
    >>
  case p as PAT_AS(ty = NONE()) then
    let &assignments += '_<%p.id%> = <%rhs%>;<%\n%>'
    <<<%patternMatch(p.pat,rhs,onPatternFail,&varDecls,&assignments)%>
    >>
  case p as PAT_AS(ty = SOME(et)) then
    let &unboxBuf = buffer ""
    let &assignments += '_<%p.id%> = <%unboxVariable(rhs, et, &unboxBuf, &varDecls)%>;<%\n%>'
    <<<%&unboxBuf%>
    <%patternMatch(p.pat,rhs,onPatternFail,&varDecls,&assignments)%>
    >>
  else 'UNKNOWN_PATTERN /* rhs: <%rhs%> */<%\n%>'
end patternMatch;

template infoArgs(Info info)
::=
  match info
  case INFO(__) then '"<%fileName%>",<%lineNumberStart%>,<%columnNumberStart%>,<%lineNumberEnd%>,<%columnNumberEnd%>,<%isReadOnly%>'
end infoArgs;

template assertCommon(Exp condition, Exp message, Context context, Text &varDecls, Info info)
::=
  let &preExpCond = buffer ""
  let &preExpMsg = buffer ""
  let condVar = daeExp(condition, context, &preExpCond, &varDecls)
  let msgVar = daeExp(message, context, &preExpMsg, &varDecls)
  <<
  <%preExpCond%>
  if (!<%condVar%>) {
    <%preExpMsg%>
    omc_fileInfo info = {<%infoArgs(info)%>};
    MODELICA_ASSERT(info, <%msgVar%>);
  }
  >>
end assertCommon;

template literalExpConst(Exp lit, Integer index) "These should all be declared static X const"
::=
  let name = '_OMC_LIT<%index%>'
  let tmp = '_OMC_LIT_STRUCT<%index%>'
  let meta = 'static modelica_metatype const <%name%>'
  match lit
  case SCONST(__) then
    let escstr = Util.escapeModelicaStringToCString(string)
    if acceptMetaModelicaGrammar() then
      match unescapedStringLength(escstr)
      case 0 then '#define <%name%> mmc_emptystring'

      case 1 then '#define <%name%> mmc_strings_len1["<%escstr%>"[0]]'
      else
      <<
      #define <%name%>_data "<%escstr%>"
      static const size_t <%name%>_strlen = <%unescapedStringLength(escstr)%>;
      static const MMC_DEFSTRINGLIT(<%tmp%>,<%name%>_strlen,<%name%>_data);
      <%meta%> = MMC_REFSTRINGLIT(<%tmp%>);
      >>
    else
      <<
      #define <%name%>_data "<%escstr%>"
      static const size_t <%name%>_strlen = <%unescapedStringLength(string)%>;
      static const char <%name%>[<%intAdd(1,unescapedStringLength(string))%>] = <%name%>_data;
      >>
  case BOX(exp=exp as ICONST(__)) then
    <<
    <%meta%> = MMC_IMMEDIATE(MMC_TAGFIXNUM(<%exp.integer%>));
    >>
  case BOX(exp=exp as BCONST(__)) then
    <<
    <%meta%> = MMC_IMMEDIATE(MMC_TAGFIXNUM(<%if exp.bool then 1 else 0%>));
    >>
  case BOX(exp=exp as RCONST(__)) then
    <<
    static const MMC_DEFREALLIT(<%tmp%>,<%exp.real%>);
    <%meta%> = MMC_REFREALLIT(<%tmp%>);
    >>
  case CONS(__) then
    <<
    static const MMC_DEFSTRUCTLIT(<%tmp%>,2,1) {<%literalExpConstBoxedVal(car)%>,<%literalExpConstBoxedVal(cdr)%>}};
    <%meta%> = MMC_REFSTRUCTLIT(<%tmp%>);
    >>
  case META_TUPLE(__) then
    <<
    static const MMC_DEFSTRUCTLIT(<%tmp%>,<%listLength(listExp)%>,0) {<%listExp |> exp => literalExpConstBoxedVal(exp); separator=","%>}};
    <%meta%> = MMC_REFSTRUCTLIT(<%tmp%>);
    >>
  case META_OPTION(exp=SOME(exp)) then
    <<
    static const MMC_DEFSTRUCTLIT(<%tmp%>,1,1) {<%literalExpConstBoxedVal(exp)%>}};
    <%meta%> = MMC_REFSTRUCTLIT(<%tmp%>);
    >>
  case METARECORDCALL(__) then
    let newIndex = getValueCtor(index)
    <<
    static const MMC_DEFSTRUCTLIT(<%tmp%>,<%intAdd(1,listLength(args))%>,<%newIndex%>) {&<%underscorePath(path)%>__desc,<%args |> exp => literalExpConstBoxedVal(exp); separator=","%>}};
    <%meta%> = MMC_REFSTRUCTLIT(<%tmp%>);
    >>
  else '<%\n%>#error "literalExpConst failed: <%printExpStr(lit)%>"<%\n%>'
end literalExpConst;

template literalExpConstBoxedVal(Exp lit)
::=
  match lit
  case ICONST(__) then 'MMC_IMMEDIATE(MMC_TAGFIXNUM(<%integer%>))'
  case BCONST(__) then 'MMC_IMMEDIATE(MMC_TAGFIXNUM(<%bool%>))'
  case LIST(valList={}) then
    <<
    MMC_REFSTRUCTLIT(mmc_nil)
    >>
  case META_OPTION(exp=NONE()) then
    <<
    MMC_REFSTRUCTLIT(mmc_none)
    >>
  case BOX(__) then literalExpConstBoxedVal(exp)
  case lit as SHARED_LITERAL(__) then '_OMC_LIT<%lit.index%>'
  else '<%\n%>#error "literalExpConstBoxedVal failed: <%printExpStr(lit)%>"<%\n%>'
end literalExpConstBoxedVal;

template equationInfo(list<SimEqSystem> eqs)
::=
  match eqs
  case {} then "const struct omc_equationInfo equation_info[1] = {{0,NULL,omc_dummyFileInfo}};"
  else
    let &preBuf = buffer ""
    let res =
    <<
    const struct omc_equationInfo equation_info[<%listLength(eqs)%>] = {
      <% eqs |> eq hasindex i0 => match eq
      case SES_RESIDUAL(__) then '{"SES_RESIDUAL <%i0%>",0,NULL,omc_dummyFileInfo}'
      case SES_SIMPLE_ASSIGN(__) then
        let var = '<%cref(cref)%>__varInfo'
        '{"SES_SIMPLE_ASSIGN <%i0%>",1,&<%var%>,<%var%>.info}'
      case SES_ARRAY_CALL_ASSIGN(__) then
        let var = '<%cref(componentRef)%>__varInfo'
        '{"SES_ARRAY_CALL_ASSIGN <%i0%>",0,NULL,omc_dummyFileInfo}'
      case SES_ALGORITHM(__) then '{"SES_ALGORITHM <%i0%>",0,NULL,omc_dummyFileInfo}'
      case SES_WHEN(__) then '{"SES_WHEN <%i0%>",0,NULL,omc_dummyFileInfo}'
      case SES_LINEAR(__) then '{"LINEAR<%index%>",0,NULL,omc_dummyFileInfo}'
      case SES_NONLINEAR(__) then
        let &preBuf += 'const omc_varInfo residualFunc<%index%>_crefs[<%listLength(crefs)%>] = {<%crefs|>cr=>'<%cref(cr)%>__varInfo'; separator=","%>};'
        '{"residualFunc<%index%>",<%listLength(crefs)%>,residualFunc<%index%>_crefs,omc_dummyFileInfo}'
      case SES_MIXED(__) then '{"MIXED<%index%>",0,NULL,omc_dummyFileInfo}'
      else '{"unknown equation <%i0%>",0,NULL,omc_dummyFileInfo}' ; separator=",\n"%>
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

end SimCodeC;

// vim: filetype=susan sw=2 sts=2
