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
  input B inCrefToSimVarHT;
  output SimCodeVar.SimVar outSimVar;
algorithm
  assert(false, getInstanceName());
end cref2simvar;

function simVarFromHT<A,B>
  input A inCref;
  input B simCode;
  output SimCodeVar.SimVar outSimVar;
algorithm
  assert(false, getInstanceName());
end simVarFromHT;

function localCref2SimVar<A,B>
  input A inCref;
  input B inCrefToSimVarHT;
  output SimCodeVar.SimVar outSimVar;
algorithm
  assert(false, getInstanceName());
end localCref2SimVar;

function localCref2Index<A,B>
  input A inCref;
  input B inOMSIFunction;
  output String outIndex;
algorithm
  assert(false, getInstanceName());
end localCref2Index;

function codegenExpSanityCheck
  input output DAE.Exp e;
  input SimCodeFunction.Context context;
algorithm
  /* Do nothing */
end codegenExpSanityCheck;

function getValueReference
  input SimCodeVar.SimVar inSimVar;
  input SimCode.SimCode inSimCode;
  input Boolean inElimNegAliases;
  output String outValueReference;
algorithm
  /* Do nothing */
end getValueReference;

function getLocalValueReference<A>
  input SimCodeVar.SimVar inSimVar;
  input SimCode.SimCode inSimCode;
  input A inCrefToSimVarHT;
  input Boolean inElimNegAliases "=false to keep negative alias references";
  output String outValueReference;
algorithm
  /* Do nothing */
end getLocalValueReference;


annotation(__OpenModelica_Interface="backend");
end SimCodeUtil;
