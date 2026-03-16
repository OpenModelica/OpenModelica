// name: Inline5
// status: correct

model Inline5
  function f
    input Real x;
    output Real y;
  algorithm
    if x <= 1 then
      y := 1;
    elseif x >= 1 and x <= 3 then
      y := 2;
    else
      y := 3;
    end if;
  end f;

  Real x = 1;
  Real y = f(x);
  annotation(__OpenModelica_commandLineOptions="-f --baseModelicaOptions=inlineFunctions");
end Inline5;

// Result:
// //! base 0.1.0
// package 'Inline5'
//   model 'Inline5'
//     Real 'x' = 1.0;
//     Real 'y' = if 'x' <= 1.0 then 1.0 else if 'x' >= 1.0 and 'x' <= 3.0 then 2.0 else 3.0;
//   end 'Inline5';
// end 'Inline5';
// endResult
