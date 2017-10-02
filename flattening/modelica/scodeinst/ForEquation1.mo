// name: ForEquation1.mo
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model ForEquation1
  Real x[5];
equation
  for i in 1:5 loop
    x[i] = i;
  end for;
end ForEquation1;

// Result:
// class ForEquation1
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real x[4];
//   Real x[5];
// equation
//   x[1] = /*Real*/(1);
//   x[2] = /*Real*/(2);
//   x[3] = /*Real*/(3);
//   x[4] = /*Real*/(4);
//   x[5] = /*Real*/(5);
// end ForEquation1;
// endResult
