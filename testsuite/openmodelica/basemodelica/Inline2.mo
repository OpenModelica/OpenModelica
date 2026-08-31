// name: Inline2
// status: correct

model Inline2
  function f
    input Real x;
    output Real y;
    external "C";
  end f;

  Real x = 1;
  Real y = f(x);
  annotation(__OpenModelica_commandLineOptions="-f --baseModelicaOptions=inlineFunctions");
end Inline2;

// Result:
// //! base 0.1.0
// package 'Inline2'
//   function 'Inline2.f'
//     input Real 'x';
//     output Real 'y';
//   external "C";
//   end 'Inline2.f';
//
//   model 'Inline2'
//     Real 'x' = 1.0;
//     Real 'y' = 'Inline2.f'('x');
//   end 'Inline2';
// end 'Inline2';
// endResult
