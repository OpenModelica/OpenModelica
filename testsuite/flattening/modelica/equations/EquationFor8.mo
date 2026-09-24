// name:     EquationFor8
// status:   correct
//
//

model EquationFor8
  constant Integer n = 0;
  Real x[n];
equation
  for i in 1:n loop
    x[i] = 0;
  end for;

  annotation(__OpenModelica_commandLineOptions="--newBackend");
end EquationFor8;

// Result:
// class EquationFor8
//   constant Integer n = 0;
// end EquationFor8;
// endResult
