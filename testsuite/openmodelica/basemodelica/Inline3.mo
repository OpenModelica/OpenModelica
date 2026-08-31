// name: Inline3
// status: correct

model Inline3
  function f
    input Real x;
    output Real y;
  algorithm
    y := 2 + x;
  end f;

  function f2
    input Real x;
    output Real y;
  algorithm
    y := x + 1;
  end f2;

  Real x = 1;
  Real y = f2(f(x));
  annotation(__OpenModelica_commandLineOptions="-f --baseModelicaOptions=inlineFunctions");
end Inline3;

// Result:
// //! base 0.1.0
// package 'Inline3'
//   model 'Inline3'
//     Real 'x' = 1.0;
//     Real 'y' = 2.0 + 'x' + 1.0;
//   end 'Inline3';
// end 'Inline3';
// endResult
