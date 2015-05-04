// name:     EquationFor7
// keywords: equation,array
// status:   correct
//
// Test for multiple loops in equations.
//

class EquationFor7
  Real a[2,3];
equation
  for i in 1:2, j in 1:3 loop
    a[i,j] =  i+j;
  end for;
end EquationFor7;

// Result:
// class EquationFor7
//   Real a[1,1];
//   Real a[1,2];
//   Real a[1,3];
//   Real a[2,1];
//   Real a[2,2];
//   Real a[2,3];
// equation
//   a[1,1] = 2.0;
//   a[1,2] = 3.0;
//   a[1,3] = 4.0;
//   a[2,1] = 3.0;
//   a[2,2] = 4.0;
//   a[2,3] = 5.0;
// end EquationFor7;
// endResult
