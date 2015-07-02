encapsulated package BackendDAEOptimize

function applyRewriteRulesBackend<T>
  input T inDAE;
  output T outDAE;
algorithm
  assert(false, getInstanceName());
end applyRewriteRulesBackend;

annotation(__OpenModelica_Interface="backend");
end BackendDAEOptimize;
