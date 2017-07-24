encapsulated package SimCodeUtil

import SimCode;
import SimCodeFunction;
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

function codegenExpSanityCheck
  input output DAE.Exp e;
  input SimCodeFunction.Context context;
algorithm
  /* Do nothing */
end codegenExpSanityCheck;


annotation(__OpenModelica_Interface="backend");
end SimCodeUtil;
