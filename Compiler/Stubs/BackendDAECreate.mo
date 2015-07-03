encapsulated package BackendDAECreate

import BackendDAE;

function lower<A,B,C,D>
  input A a;
  input B b;
  input C c;
  input D d;
  output BackendDAE.BackendDAE outBackendDAE;
algorithm
  assert(false, getInstanceName());
end lower;

annotation(__OpenModelica_Interface="backend");
end BackendDAECreate;
