// name:     EquationFor5
// keywords: equation,array
// status:   correct
//
// Test for loops in equations.
//

class EquationFor5
  Real a[4];
equation
  for i in 2:2:4 loop
    a[i] = a[i-1] + 1.0;
  end for;
end EquationFor5;

// Result:
// class EquationFor5
//   Real a[1];
//   Real a[2];
//   Real a[3];
//   Real a[4];
// equation
//   a[2] = a[1] + 1.0;
//   a[4] = a[3] + 1.0;
// end EquationFor5;
// [flattening/modelica/equations/EquationFor5.mo:9:3-9:12:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/EquationFor5.mo:11:3-13:10:writable] Warning: Equation sections are deprecated in class.
//
// endResult
