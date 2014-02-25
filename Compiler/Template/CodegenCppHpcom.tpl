// This file defines template-extensions for transforming Modelica code into parallel hpcom-code.
//
// There are one root template intended to be called from the code generator:
// translateModel. These template do not return any
// result but instead write the result to files. All other templates return
// text and are used by the root templates (most of them indirectly).

package CodegenCppHpcom

import interface SimCodeTV;
import CodegenUtil.*;
import CodegenCpp.*; //unqualified import, no need the CodegenC is optional when calling a template; or mandatory when the same named template exists in this package (name hiding)


// ----------------------
// BEGIN COPIED FUNCTIONS
// ----------------------

template translateModel(SimCode simCode) ::=
  match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
  let target  = simulationCodeTarget()
   let()= textFile(simulationMainFile(simCode), 'OMCpp<%fileNamePrefix%>Main.cpp')
  let()= textFile(simulationHeaderFile(simCode), 'OMCpp<%fileNamePrefix%>.h')
  let()= textFile(simulationCppFile(simCode), 'OMCpp<%fileNamePrefix%>.cpp')
  let()= textFile(simulationFunctionsHeaderFile(simCode,modelInfo.functions,literals), 'OMCpp<%fileNamePrefix%>Functions.h')
  let()= textFile(simulationFunctionsFile(simCode, modelInfo.functions,literals,externalFunctionIncludes), 'OMCpp<%fileNamePrefix%>Functions.cpp')
  let()= textFile(simulationMakefile(target,simCode), '<%fileNamePrefix%>.makefile')
  let()= textFile(simulationInitHeaderFile(simCode), 'OMCpp<%fileNamePrefix%>Initialize.h')
  let()= textFile(simulationInitCppFile(simCode),'OMCpp<%fileNamePrefix%>Initialize.cpp')
  let()= textFile(simulationJacobianHeaderFile(simCode), 'OMCpp<%fileNamePrefix%>Jacobian.h')
  let()= textFile(simulationJacobianCppFile(simCode),'OMCpp<%fileNamePrefix%>Jacobian.cpp')
  let()= textFile(simulationExtensionHeaderFile(simCode),'OMCpp<%fileNamePrefix%>Extension.h')
  let()= textFile(simulationExtensionCppFile(simCode),'OMCpp<%fileNamePrefix%>Extension.cpp')
  let()= textFile(simulationWriteOutputHeaderFile(simCode),'OMCpp<%fileNamePrefix%>WriteOutput.h')
  let()= textFile(simulationWriteOutputCppFile(simCode),'OMCpp<%fileNamePrefix%>WriteOutput.cpp')
  let()= textFile(simulationFactoryFile(simCode),'OMCpp<%fileNamePrefix%>FactoryExport.cpp')
  let()= textFile(simulationMainRunScrip(simCode), '<%fileNamePrefix%><%simulationMainRunScripSuffix(simCode)%>')
  algloopfiles(listAppend(allEquations,initialEquations),simCode)
  // empty result of the top-level template .., only side effects
end translateModel;

template simulationCppFile(SimCode simCode)
 "Generates code for main cpp file for simulation target."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  <<
   #include "Modelica.h"
   #include "OMCpp<%fileNamePrefix%>.h"
   #include <omp.h>

 
    
    <%lastIdentOfPath(modelInfo.name)%>::<%lastIdentOfPath(modelInfo.name)%>(IGlobalSettings* globalSettings,boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory,boost::shared_ptr<ISimData> simData) 
   :SystemDefaultImplementation(*globalSettings)
    ,_algLoopSolverFactory(nonlinsolverfactory)
    ,_simData(simData)
    <%simulationInitFile(simCode)%>
    {
    //Number of equations
    <%dimension1(simCode)%>
    _dimZeroFunc= <%zerocrosslength(simCode)%>;
    _dimTimeEvent = <%timeeventlength(simCode)%>;
    //Number of residues
    <%if Flags.isSet(Flags.WRITE_TO_BUFFER) then
      <<
      _dimResidues=<%numResidues(allEquations)%>;
      >>

    %>
    //DAE's are not supported yet, Index reduction is enabled
    _dimAE = 0; // algebraic equations
    //Initialize the state vector
    SystemDefaultImplementation::initialize();
    //Instantiate auxiliary object for event handling functionality
    _event_handling.getCondition =  boost::bind(&<%lastIdentOfPath(modelInfo.name)%>::getCondition, this, _1);
     <%arrayReindex(modelInfo)%>
    //Initialize array elements
    <%initializeArrayElements(simCode)%>
   
   

    }
    <%lastIdentOfPath(modelInfo.name)%>::~<%lastIdentOfPath(modelInfo.name)%>()
    {
   
    }
  
  
   <%Update(simCode)%>
  
   <%DefaultImplementationCode(simCode)%>
   <%checkForDiscreteEvents(discreteModelVars,simCode)%>
   <%giveZeroFunc1(zeroCrossings,simCode)%>
   <%setConditions(simCode)%>
   <%geConditions(simCode)%>
   <%isConsistent(simCode)%>
   <%generateStepCompleted(listAppend(allEquations,initialEquations),simCode)%>
   <%generatehandleTimeEvent(timeEvents, simCode)%>
   <%generateDimTimeEvent(listAppend(allEquations,initialEquations),simCode)%>
   <%generateTimeEvent(timeEvents, simCode)%>
   
   
   <%isODE(simCode)%>
   <%DimZeroFunc(simCode)%>
  
   
  
   <%getCondition(zeroCrossings,whenClauses,simCode)%>
   <%handleSystemEvents(zeroCrossings,whenClauses,simCode)%>
   <%saveall(modelInfo,simCode)%>
   <%savediscreteVars(modelInfo,simCode)%>
   <%LabeledDAE(modelInfo.labels,simCode)%>
    <%giveVariables(modelInfo)%>
   >>
end simulationCppFile;

template Update(SimCode simCode)
::=
match simCode
case SIMCODE(__) then
  <<
  <%update(allEquations,whenClauses,simCode,contextOther)%>
  >>
end Update;

// --------------------
// END COPIED FUNCTIONS
// --------------------

template update( list<SimEqSystem> allEquationsPlusWhen,list<SimWhenClause> whenClauses, SimCode simCode, Context context)
::=
  let &varDecls = buffer "" /*BUFD*/
  let all_equations = (allEquationsPlusWhen |> eqs => (eqs |> eq =>
      equation_(eq, contextSimulationDiscrete, &varDecls /*BUFC*/,simCode))
    ;separator="\n")

  let reinit = (whenClauses |> when hasindex i0 =>
         genreinits(when, &varDecls,i0,simCode,context)
    ;separator="\n";empty)
  match simCode
  case SIMCODE(modelInfo = MODELINFO(__)) then
      let parCode = update2(allEquationsPlusWhen, hpcOmSchedule, &varDecls, simCode)
      <<
      bool <%lastIdentOfPath(modelInfo.name)%>::evaluate(const UPDATETYPE command)
    
      {
        bool state_var_reinitialized = false;
        <%varDecls%>
        <%parCode%>
        <%reinit%>
       
        return state_var_reinitialized;
      }
      >>
end update;

template update2(list<SimEqSystem> allEquationsPlusWhen, Option<ScheduleSimCode> hpcOmScheduleOpt, Text &varDecls, SimCode simCode)
::=
  match hpcOmScheduleOpt 
    case SOME(hpcOmSchedule as LEVELSCHEDULESC(__)) then
      let odeEqs = hpcOmSchedule.eqsOfLevels |> eqs => functionXXX_system0_HPCOM_Level(allEquationsPlusWhen, eqs, &varDecls, simCode); separator="\n"
      <<      
        <%odeEqs%>
      >>
end update2;

template functionXXX_system0_HPCOM_Level(list<SimEqSystem> allEquationsPlusWhen, list<Integer> eqsOfLevel, Text &varDecls, SimCode simCode)
::=
  let odeEqs = eqsOfLevel |> eq => equationNamesHPCOM_(eq,allEquationsPlusWhen,contextSimulationNonDiscrete, &varDecls, simCode); separator="\n"
  <<
  if (omp_get_dynamic())
    omp_set_dynamic(0);
  #pragma omp parallel sections num_threads(<%getConfigInt(NUM_PROC)%>)
  {
     <%odeEqs%>
  }
  >>
end functionXXX_system0_HPCOM_Level;

template equationNamesHPCOM_(Integer idx, list<SimEqSystem> allEquationsPlusWhen, Context context, Text &varDecls, SimCode simCode)
 "Generates an equation.
  This template should not be used for a SES_RESIDUAL.
  Residual equations are handled differently."
::=
    let eq =  equation_(getSimCodeEqByIndex(allEquationsPlusWhen, idx), context, &varDecls, simCode)
    <<
    #pragma omp section
    {
        <%eq%>
    }
    >>
end equationNamesHPCOM_;

end CodegenCppHpcom;