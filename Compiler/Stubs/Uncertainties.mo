encapsulated package Uncertainties

import Values;

function modelEquationsUC<A,B,C,D>
  input A inCache;
  input B inEnv;
  input C className;
  input D inInteractiveSymbolTable;
  input String outputFileIn;
  input Boolean dumpSteps;
  output A outCache;
  output Values.Value outValue;
  output D outInteractiveSymbolTable;
algorithm
  assert(false, getInstanceName());
end modelEquationsUC;

annotation(__OpenModelica_Interface="backend");
end Uncertainties;
