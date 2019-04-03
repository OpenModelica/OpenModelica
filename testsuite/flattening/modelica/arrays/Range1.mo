// name:     Range1
// keywords: array
// status:   correct
//
// Some tests of range expressions.
//

class Range1
  Integer x[5] = 1:5;
  Integer y[5], z[5];
equation
  for i in 1:5 loop
    y[i] = x[i] + 1;
  end for;

  for i in 1:2:5 loop
    z[i] = x[i] + 2;
  end for;
  z[2]=1;
  z[4]=2;
end Range1;

// Result:
// class Range1
//   Integer x[1];
//   Integer x[2];
//   Integer x[3];
//   Integer x[4];
//   Integer x[5];
//   Integer y[1];
//   Integer y[2];
//   Integer y[3];
//   Integer y[4];
//   Integer y[5];
//   Integer z[1];
//   Integer z[2];
//   Integer z[3];
//   Integer z[4];
//   Integer z[5];
// equation
//   x = {1, 2, 3, 4, 5};
//   y[1] = 1 + x[1];
//   y[2] = 1 + x[2];
//   y[3] = 1 + x[3];
//   y[4] = 1 + x[4];
//   y[5] = 1 + x[5];
//   z[1] = 2 + x[1];
//   z[3] = 2 + x[3];
//   z[5] = 2 + x[5];
//   z[2] = 1;
//   z[4] = 2;
// end Range1;
// endResult
