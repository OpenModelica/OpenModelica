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
  Real t;
equation
  t = myTan(1.0);
end myTanCall;

// Result:
// class myTanCall
//   Real t;
// equation
//   t = 1.557407724654902;
// end myTanCall;
// [flattening/modelica/extends/OneArgBaseFunction.mo:28:3-28:9:writable] Warning: Components are deprecated in class.
// [flattening/modelica/extends/OneArgBaseFunction.mo:30:3-30:17:writable] Warning: Equation sections are deprecated in class.
//
// endResult
