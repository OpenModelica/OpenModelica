encapsulated package BackendDAEUtil

import BackendDAE;

function getSolvedSystem<A>
  input A inDAE;
  input String fileNamePrefix;
  input Option<list<String>> strPreOptModules = NONE();
  input Option<String> strmatchingAlgorithm = NONE();
  input Option<String> strdaeHandler = NONE();
  input Option<list<String>> strPostOptModules = NONE();
  output A outSODE;
algorithm
  assert(false, getInstanceName());
end getSolvedSystem;

function preOptimizeBackendDAE<T>
  input T inDAE;
  input Option<list<String>> strPreOptModules;
  output T outDAE;
algorithm
  assert(false, getInstanceName());
end preOptimizeBackendDAE;

function transformBackendDAE<A,B>
  input A inDAE;
  input Option<B> inMatchingOptions;
  input Option<String> strmatchingAlgorithm;
  input Option<String> strindexReductionMethod;
  output A outDAE;
algorithm
  assert(false, getInstanceName());
end transformBackendDAE;

function getIncidenceMatrixfromOption
  input BackendDAE.EqSystem inSyst;
  input BackendDAE.IndexType inIndxType;
  input Option<DAE.FunctionTree> inFunctionTree;
  output BackendDAE.EqSystem outSyst;
  output BackendDAE.IncidenceMatrix outM;
  output BackendDAE.IncidenceMatrix outMT;
algorithm
  assert(false, getInstanceName());
end getIncidenceMatrixfromOption;

function getAllVarLst
  input BackendDAE.BackendDAE dae;
  output list<BackendDAE.Var> varLst;
algorithm
  assert(false, getInstanceName());
end getAllVarLst;

annotation(__OpenModelica_Interface="backend");
end BackendDAEUtil;
