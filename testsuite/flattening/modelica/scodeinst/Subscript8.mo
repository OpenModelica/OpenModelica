// name: Subscript8
// keywords:
// status: correct
//
// Literal indices of inner dimensions are applied to an array literal even if
// the outer index is not known.
//

model Subscript8
  constant Real c[3, 2] = {{1, 2}, {3, 4}, {5, 6}};
  Real x[3];
equation
  for i in 1:3 loop
    x[i] = c[i, 2]*time;
  end for;
  annotation(__OpenModelica_commandLineOptions="-d=-nfScalarize");
end Subscript8;

// Result:
// class Subscript8
//   constant Real[3, 2] c = {{1.0, 2.0}, {3.0, 4.0}, {5.0, 6.0}};
//   Real[3] x;
// equation
//   for i in 1:3 loop
//     x[i] = {2.0, 4.0, 6.0}[i] * time;
//   end for;
// end Subscript8;
// endResult
