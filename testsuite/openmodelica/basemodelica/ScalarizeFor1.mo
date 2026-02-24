// name: ScalarizeFor1
// status: correct

model ScalarizeFor1
  parameter Integer N = 3;
  Real x[N];
algorithm
  for i in 1:N loop
    x[i] := 0.1 * i;
  end for;
  annotation(__OpenModelica_commandLineOptions="-f --baseModelicaOptions=scalarize");
end ScalarizeFor1;

// Result:
// //! base 0.1.0
// package 'ScalarizeFor1'
//   model 'ScalarizeFor1'
//     parameter Integer 'N' = 3;
//     Real 'x[1]';
//     Real 'x[2]';
//     Real 'x[3]';
//   algorithm
//     'x[1]' := 0.1 * 1;
//     'x[2]' := 0.1 * 2;
//     'x[3]' := 0.1 * 3;
//   end 'ScalarizeFor1';
// end 'ScalarizeFor1';
// endResult
