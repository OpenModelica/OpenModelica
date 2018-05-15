// name: ForEquation3.mo
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model ForEquation3
  Real x[5];
equation
  for i in {1, 2, 3, 4, 5} loop
    x[i] = i;
  end for;
end ForEquation3;

// Result:
// class ForEquation3
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real x[4];
//   Real x[5];
// equation
//   x[1] = 1.0;
//   x[2] = 2.0;
//   x[3] = 3.0;
//   x[4] = 4.0;
//   x[5] = 5.0;
// end ForEquation3;
// endResult
