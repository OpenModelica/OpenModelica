encapsulated package CevalScriptBackend

import Absyn;
import DAE;
import FCore;
import GlobalScript;
import Values;

function runFrontEnd
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path className;
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
  input Boolean relaxedFrontEnd "Do not check for illegal simulation models, so we allow instantation of packages, etc";
  output FCore.Cache cache;
  output FCore.Graph env;
  output DAE.DAElist dae;
  output GlobalScript.SymbolTable st;
algorithm
  assert(false, getInstanceName());
end runFrontEnd;

function getSimulationResultType
  output DAE.Type t;
algorithm
  assert(false, getInstanceName());
end getSimulationResultType;

function getDrModelicaSimulationResultType = getSimulationResultType;

function buildSimulationOptionsFromModelExperimentAnnotation
  input GlobalScript.SymbolTable inSymTab;
  input Absyn.Path inModelPath;
  input String inFileNamePrefix;
  input Option<GlobalScript.SimulationOptions> defaultOption;
  output GlobalScript.SimulationOptions outSimOpt;
algorithm
  assert(false, getInstanceName());
end buildSimulationOptionsFromModelExperimentAnnotation;

function getSimulationOption
  input GlobalScript.SimulationOptions inSimOpt;
  input String optionName;
  output DAE.Exp outOptionValue;
algorithm
  assert(false, getInstanceName());
end getSimulationOption;

function cevalInteractiveFunctions3
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input String inFunctionName;
  input list<Values.Value> inVals;
  input GlobalScript.SymbolTable inSt;
  input Absyn.Msg msg;
  output FCore.Cache outCache = inCache;
  output Values.Value outValue = Values.INTEGER(0);
  output GlobalScript.SymbolTable outInteractiveSymbolTable = inSt;
algorithm
  assert(false, getInstanceName() + ": " + inFunctionName);
end cevalInteractiveFunctions3;

annotation(__OpenModelica_Interface="backend");
end CevalScriptBackend;
