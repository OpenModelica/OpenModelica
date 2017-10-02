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
//   x[1] = /*Real*/(1);
//   x[2] = /*Real*/(2);
//   x[3] = /*Real*/(3);
//   x[4] = 0.0;
// end ForEquation5;
// endResult
