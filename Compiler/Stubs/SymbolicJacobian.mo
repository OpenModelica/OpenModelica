encapsulated package SymbolicJacobian

import BackendDAE;

function calculateJacobian
  input BackendDAE.Variables inVariables;
  input BackendDAE.EquationArray inEquationArray;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input Boolean differentiateIfExp;
  input BackendDAE.Shared iShared;
  output Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> outTplIntegerIntegerEquationLstOption;
  output BackendDAE.Shared oShared;
algorithm
  assert(false, getInstanceName());
end calculateJacobian;

annotation(__OpenModelica_Interface="backend");
end SymbolicJacobian;
