// name: ForEquation5.mo
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model ForEquation5
  constant Integer N = 4;
  Real x[N];
equation
  for i in 1:N-1 loop
    x[i] = i;
  end for;
  x[4] = 0;
end ForEquation5;

// Result:
// class ForEquation5
//   constant Integer N = 4;
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real x[4];
// equation
//   x[1] = 1.0;
//   x[2] = 2.0;
//   x[3] = 3.0;
//   x[4] = 0.0;
// end ForEquation5;
// endResult
