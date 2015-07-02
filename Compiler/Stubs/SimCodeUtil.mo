encapsulated package SimCodeUtil

function sortEqSystems<T>
  input T eqs;
  output T outEqs;
algorithm
  assert(false, getInstanceName());
end sortEqSystems;

public function eqInfo<T>
  input T eq;
  output SourceInfo info;
algorithm
  assert(false, getInstanceName());
end eqInfo;

annotation(__OpenModelica_Interface="backend");
end SimCodeUtil;
