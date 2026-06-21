encapsulated package MidCodeUtil

function getFunctionDependencies<T1,T2,T3>
  input T1 t1;
  input T2 t2;
  output list<Integer> t3;
algorithm
  assert(false, getInstanceName());
end getFunctionDependencies;

function addMidCodeFunctions<T1,T2>
  input T1 t1;
  input output T2 t2;
algorithm
  assert(false, getInstanceName());
end addMidCodeFunctions;

annotation(__OpenModelica_Interface="backend");
end MidCodeUtil;
