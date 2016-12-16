encapsulated package SimCodeUtil

import SimCode;
import SimCodeVar;

function sortEqSystems<T>
  input T eqs;
  output T outEqs;
algorithm
  assert(false, getInstanceName());
end sortEqSystems;

function eqInfo<T>
  input T eq;
  output SourceInfo info;
algorithm
  assert(false, getInstanceName());
end eqInfo;

function getSimCode
  output SimCode.SimCode code;
algorithm
  assert(false, getInstanceName());
end getSimCode;

function cref2simvar<A,B>
  input A inCref;
  input B simCode;
  output SimCodeVar.SimVar outSimVar;
algorithm
  assert(false, getInstanceName());
end cref2simvar;

annotation(__OpenModelica_Interface="backend");
end SimCodeUtil;
