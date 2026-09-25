// name:     EquationFor9
// status:   correct
//
//

model EquationFor9
  constant Integer n = 1;
  Real x[n];
equation
  for i in 1:n loop
    x[i] = 0;
  end for;

  annotation(__OpenModelica_commandLineOptions="--newBackend");
end EquationFor9;

// Result:
// class EquationFor9
//   constant Integer n = 1;
//   Real[1] x;
// equation
//   x[1] = 0.0;
// end EquationFor9;
// endResult
