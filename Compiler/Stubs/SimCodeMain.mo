encapsulated package SimCodeMain

import BackendDAE;
import SimCode;
import Values;

function createSimulationSettings
  input Real startTime;
  input Real stopTime;
  input Integer inumberOfIntervals;
  input Real tolerance;
  input String method;
  input String options;
  input String outputFormat;
  input String variableFilter;
  input String cflags;
  output SimCode.SimulationSettings simSettings;
algorithm
  assert(false, getInstanceName());
end createSimulationSettings;

function generateModelCode<T,A,B,C,D,E,F>
  input T inBackendDAE;
  input T inInitDAE;
  input Option<T> inInitDAE_lambda0;
  input Option<F> inInlineDAE;
  input list<BackendDAE.Equation> inRemovedInitialEquationLst;
  input A p;
  input C className;
  input String filenamePrefix;
  input D simSettingsOpt;
  input E args;
  output list<String> libs;
  output String fileDir;
  output Real timeSimCode;
  output Real timeTemplates;
algorithm
  assert(false, getInstanceName());
end generateModelCode;

function translateModel<A,B,C,D,E,F,G>
  input G x;
  input A inCache;
  input B inEnv;
  input C className;
  input D inInteractiveSymbolTable;
  input String inFileNamePrefix;
  input Boolean addDummy;
  input Option<E> inSimSettingsOpt;
  input F args;
  output A outCache;
  output D outInteractiveSymbolTable;
  output BackendDAE.BackendDAE outBackendDAE;
  output list<String> outStringLst;
  output String outFileDir;
  output list<tuple<String, Values.Value>> resultValues;
algorithm
  assert(false, getInstanceName());
end translateModel;

annotation(__OpenModelica_Interface="backend");
end SimCodeMain;
