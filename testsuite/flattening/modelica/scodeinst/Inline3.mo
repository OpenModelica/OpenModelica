// name: Inline3
// keywords:
// status: correct
//

function f
  input Real x[3];
  input Real y[3];
  output Real z;
algorithm
  z := x * y;
  annotation(Inline = true);
end f;

model Inline3
  Real x = f({1, 2, 3}, {time, time, time});
  annotation(__OpenModelica_commandLineOptions="--frontendInline");
end Inline3;

// Result:
// class Inline3
//   Real x = time + 2.0 * time + 3.0 * time;
// end Inline3;
// endResult
