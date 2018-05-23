// name: ForEquation6
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model ForEquation6
  Real x[3];
  Real y[3];
equation
  for i in 1:3 loop
    x[i] = i;
    y[i] = i;
  end for;
end ForEquation6;

// Result:
// class ForEquation6
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real y[1];
//   Real y[2];
//   Real y[3];
// equation
//   x[1] = 1.0;
//   y[1] = 1.0;
//   x[2] = 2.0;
//   y[2] = 2.0;
//   x[3] = 3.0;
//   y[3] = 3.0;
// end ForEquation6;
// endResult
