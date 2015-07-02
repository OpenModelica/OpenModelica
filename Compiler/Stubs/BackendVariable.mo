encapsulated package BackendVariable

import BackendDAE;

function getVar<A,B>
  input A cr;
  input B inVariables;
  output list<BackendDAE.Var> outVarLst;
  output list<Integer> outIntegerLst;
algorithm
  assert(false, getInstanceName());
end getVar;

function daeVars
  input BackendDAE.EqSystem syst;
  output BackendDAE.Variables vars;
algorithm
  assert(false, getInstanceName());
end daeVars;

function varEqual<A>
  input A inVar1;
  input A inVar2;
  output Boolean outBoolean;
algorithm
  assert(false, getInstanceName());
end varEqual;

function isStateVar<A>
  input A inVar;
  output Boolean outBoolean;
algorithm
  assert(false, getInstanceName());
end isStateVar;

annotation(__OpenModelica_Interface="backend");
end BackendVariable;
