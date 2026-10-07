// name:     EquationFor3
// keywords: equation,array
// status:   correct
//
// Test for loops in equations.  The size is a parameter.
//

class EquationFor3
  parameter Integer N = 4;
  Real a[N];
equation
  a[1] = 1.0;
  for i in 1:N-1 loop
    a[i+1] = a[i] + 1.0;
  end for;
end EquationFor3;

// Result:
// class EquationFor3
//   final parameter Integer N = 4;
//   Real a[1];
//   Real a[2];
//   Real a[3];
//   Real a[4];
// equation
//   a[1] = 1.0;
//   a[2] = a[1] + 1.0;
//   a[3] = a[2] + 1.0;
//   a[4] = a[3] + 1.0;
// end EquationFor3;
// [flattening/modelica/equations/EquationFor3.mo:9:3-9:26:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/EquationFor3.mo:10:3-10:12:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/EquationFor3.mo:12:3-12:13:writable] Warning: Equation sections are deprecated in class.
//
// endResult
