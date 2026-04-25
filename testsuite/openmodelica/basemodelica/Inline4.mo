// name: Inline4
// status: correct

model Inline4
  record R
    Real x[1];
  end R;

  function f
    input Real x[:];
    output R r;
  algorithm
    r := R(x = cat(1, x, {1}));
  end f;

  Real x = 1;
  R r = f({x});
  annotation(__OpenModelica_commandLineOptions="-f --baseModelicaOptions=inlineFunctions");
end Inline4;

// Result:
// //! base 0.1.0
// package 'Inline4'
//   record 'R'
//     Real 'x'[1];
//   end 'R';
//
//   model 'Inline4'
//     Real 'x' = 1.0;
//     'R' 'r';
//   equation
//     'r' = 'R'(cat(1, {'x'}, {1.0}));
//   end 'Inline4';
// end 'Inline4';
// endResult
