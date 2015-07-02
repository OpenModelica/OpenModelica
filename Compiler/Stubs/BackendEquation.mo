encapsulated package BackendEquation

import BackendDAE;

function getEqnsFromEqSystem
  input BackendDAE.EqSystem inEqSystem;
  output BackendDAE.EquationArray outOrderedEqs;
algorithm
  assert(false, getInstanceName());
end getEqnsFromEqSystem;

annotation(__OpenModelica_Interface="backend");
end BackendEquation;
