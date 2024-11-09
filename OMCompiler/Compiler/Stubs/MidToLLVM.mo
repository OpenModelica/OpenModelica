encapsulated package MidToLLVM

function genProgram<T>
  input T t;
algorithm
  assert(false, getInstanceName());
end genProgram;

function genRecordDecls<T>
  input T t;
algorithm
  assert(false, getInstanceName());
end genRecordDecls;

function JIT<T1,T2>
  input T1 t1;
  input list<T2> t2;
  output T2 t3;
algorithm
  assert(false, getInstanceName());
end JIT;

annotation(__OpenModelica_Interface="backend");
end MidToLLVM;
