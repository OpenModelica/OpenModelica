// name: FunctionInverseInvalid1
// keywords: inverse
// status: correct
//

function f
  input Real x;
  input Real y;
  output Real z;
algorithm
  z := x + y;
  annotation(inverse(y = z));
end f;

model FunctionInverseInvalid1
  Real x = f(1, 2);
end FunctionInverseInvalid1;

// Result:
// class FunctionInverseInvalid1
//   Real x = 3.0;
// end FunctionInverseInvalid1;
// [flattening/modelica/scodeinst/FunctionInverseInvalid1.mo:12:14-12:28:writable] Warning: 'y = z' is not a valid function inverse attribute.
//
// endResult
