// name: ForEquation4.mo
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model ForEquation4
  constant Integer N = 4;
  Real x[N];
equation
  for i in 1:N loop
    x[i] = i;
  end for;
end ForEquation4;

// Result:
// class ForEquation4
//   constant Integer N = 4;
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real x[4];
// equation
//   x[1] = /*Real*/(1);
//   x[2] = /*Real*/(2);
//   x[3] = /*Real*/(3);
//   x[4] = /*Real*/(4);
// end ForEquation4;
// endResult
