// name:     OneArgBaseFunction
// keywords: Inheritance
// status:   correct
//
// Tests inheritance in many steps
//
// Drmodelica: 9.2 Partial Base Function (p. 308)
//
partial function OneArgBaseFunction
  input Real x;
  output Real result;
end OneArgBaseFunction;

function myTan
  extends OneArgBaseFunction;
algorithm
  result := sin(x)/cos(x);
end myTan;

function addTen
  extends OneArgBaseFunction;
algorithm
  result := x + 10;
end addTen;

class myTanCall
  Real t,t1;
equation
  t = myTan(1.0);
  t1 = addTen(t);
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end myTanCall;
