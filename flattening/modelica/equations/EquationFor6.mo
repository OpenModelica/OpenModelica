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
// endResult
