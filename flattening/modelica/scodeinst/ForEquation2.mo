// name: ForEquation2.mo
// keywords:
// status: correct
// cflags: -d=newInst
//

model ForEquation2
  Real x[3,3];
equation
  for i in 1:2 loop
    for i in 1:3 loop
      x[i, i] = i;
    end for;
  end for;
end ForEquation2;

// Result:
// class ForEquation2
//   Real x[1,1];
//   Real x[1,2];
//   Real x[1,3];
//   Real x[2,1];
//   Real x[2,2];
//   Real x[2,3];
//   Real x[3,1];
//   Real x[3,2];
//   Real x[3,3];
// equation
//   x[1,1] = 1.0;
//   x[2,2] = 2.0;
//   x[3,3] = 3.0;
//   x[1,1] = 1.0;
//   x[2,2] = 2.0;
//   x[3,3] = 3.0;
// end ForEquation2;
// endResult
