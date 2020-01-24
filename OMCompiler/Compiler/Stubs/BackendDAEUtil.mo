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
  output A outInitDAE;
  output Option<A> outInitDAE_lambda0;
  output Option<BackendDAE.InlineData> inlineData;
  output list<BackendDAE.Equation> outRemovedInitialEquationLst;
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

function getAdjacencyMatrixfromOption
  input BackendDAE.EqSystem inSyst;
  input BackendDAE.IndexType inIndxType;
  input Option<DAE.FunctionTree> inFunctionTree;
  output BackendDAE.EqSystem outSyst;
  output BackendDAE.AdjacencyMatrix outM;
  output BackendDAE.AdjacencyMatrix outMT;
algorithm
  assert(false, getInstanceName());
end getAdjacencyMatrixfromOption;

function getAllVarLst
  input BackendDAE.BackendDAE dae;
  output list<BackendDAE.Var> varLst;
algorithm
  assert(false, getInstanceName());
end getAllVarLst;

annotation(__OpenModelica_Interface="backend");
end BackendDAEUtil;
