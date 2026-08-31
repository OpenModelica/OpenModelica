// name: Inline1
// status: correct

model Inline1
  function f
    input Real x;
    output Real y;
  algorithm
    y := 2 * x;
  end f;

  Real x = 1;
  Real y = f(x);
  Real z = 1 + f(x);
  annotation(__OpenModelica_commandLineOptions="-f --baseModelicaOptions=inlineFunctions");
end Inline1;

// Result:
// //! base 0.1.0
// package 'Inline1'
//   model 'Inline1'
//     Real 'x' = 1.0;
//     Real 'y' = 2.0 * 'x';
//     Real 'z' = 1.0 + 2.0 * 'x';
//   end 'Inline1';
// end 'Inline1';
// endResult
