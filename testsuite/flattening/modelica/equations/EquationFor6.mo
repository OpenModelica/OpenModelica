// name:     EquationFor6
// keywords: equation,array
// status:   correct
//
// Test for loops with implicit range in equations.
//

class EquationFor6
  Real a[3];
equation
  for i loop
    a[i] = i;
  end for;
end EquationFor6;

// Result:
// class EquationFor6
//   Real a[1];
//   Real a[2];
//   Real a[3];
// equation
//   a[1] = 1.0;
//   a[2] = 2.0;
//   a[3] = 3.0;
// end EquationFor6;
// [flattening/modelica/equations/EquationFor6.mo:9:3-9:12:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/EquationFor6.mo:11:3-13:10:writable] Warning: Equation sections are deprecated in class.
//
// endResult
