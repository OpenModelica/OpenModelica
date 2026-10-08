// name: ForEquation8
// keywords:
// status: correct
//
//

model ForEquation8
  Real x[3];
equation
  for i in 1:3 loop
    x[i] = sum({j for j in 1:i-1});
  end for;
end ForEquation8;

// Result:
// class ForEquation8
//   Real x[1];
//   Real x[2];
//   Real x[3];
// equation
//   x[1] = 0.0;
//   x[2] = 1.0;
//   x[3] = 3.0;
// end ForEquation8;
// endResult
