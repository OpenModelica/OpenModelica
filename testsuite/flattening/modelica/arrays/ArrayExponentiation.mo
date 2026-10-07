// name:     ArrayExponentiation
// keywords: array
// status:   correct
//
// Drmodelica: 7.6 Arithmetic Array Operators (p. 223)
//

class Exp
  Real e1[2, 2];
  Real e2[2, 2];
equation

  e1 = {{1, 2}, {1, 2}} ^ 0;
// Result: {{1, 0}, {0, 1}}

  e2 = [1, 2; 1, 2] ^ 2;
// Result: {{3, 6}, {3, 6}}
end Exp;

// Result:
// class Exp
//   Real e1[1,1];
//   Real e1[1,2];
//   Real e1[2,1];
//   Real e1[2,2];
//   Real e2[1,1];
//   Real e2[1,2];
//   Real e2[2,1];
//   Real e2[2,2];
// equation
//   e1[1,1] = 1.0;
//   e1[1,2] = 0.0;
//   e1[2,1] = 0.0;
//   e1[2,2] = 1.0;
//   e2[1,1] = 3.0;
//   e2[1,2] = 6.0;
//   e2[2,1] = 3.0;
//   e2[2,2] = 6.0;
// end Exp;
// [flattening/modelica/arrays/ArrayExponentiation.mo:9:3-9:16:writable] Warning: Components are deprecated in class.
// [flattening/modelica/arrays/ArrayExponentiation.mo:10:3-10:16:writable] Warning: Components are deprecated in class.
// [flattening/modelica/arrays/ArrayExponentiation.mo:13:3-13:28:writable] Warning: Equation sections are deprecated in class.
//
// endResult
