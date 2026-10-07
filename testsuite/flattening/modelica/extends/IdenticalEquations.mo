// name:     IdenticalEquations
// keywords: identical equations inheritance
// status:   correct
//
// Checks that identical equations from inheritance are not merged.
//

class Color
  parameter Real red=0.2;
  parameter Real blue=0.6;
  Real green;
equation
  red + blue + green = 1;
end Color;

class Color2
  extends Color;
equation
  red + blue + green = 1;
end Color2;

// Result:
// class Color2
//   parameter Real red = 0.2;
//   parameter Real blue = 0.6;
//   Real green;
// equation
//   red + blue + green = 1.0;
//   red + blue + green = 1.0;
// end Color2;
// [flattening/modelica/extends/IdenticalEquations.mo:19:3-19:25:writable] Warning: Equation sections are deprecated in class.
//
// endResult
