// name: NoScalarize1
// keywords:
// status: correct
//

model NoScalarize1
  Real x[3];
  Real y;
  Real z;
initial equation
  for i in 1:2 loop
    x[i] = 2;
  end for;
  x[3] = 4;
equation
  der(x) = {y, z, y};
  z = 2*y;
  y = 4*x[1];

  for i in 1:2 loop
    x[i] = 3;
  end for;
  annotation(__OpenModelica_commandLineOptions="-d=-nfScalarize");
end NoScalarize1;

// Result:
// class NoScalarize1
//   Real[3] x;
//   Real y;
//   Real z;
// initial equation
//   for i in 1:2 loop
//     x[i] = 2.0;
//   end for;
//   x[3] = 4.0;
// equation
//   der(x) = {y, z, y};
//   z = 2.0 * y;
//   y = 4.0 * x[1];
//   for i in 1:2 loop
//     x[i] = 3.0;
//   end for;
// end NoScalarize1;
// endResult
