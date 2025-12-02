// name: ForEquation2.mo
// keywords:
// status: correct
//

model ForEquation2
  Real x[3,3];
equation
  for i in 1:2 loop
    for j in 1:3 loop
      x[i, j] = i*j;
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
//   x[1,2] = 2.0;
//   x[1,3] = 3.0;
//   x[2,1] = 2.0;
//   x[2,2] = 4.0;
//   x[2,3] = 6.0;
// end ForEquation2;
// endResult
