// name: Inline6
// status: correct

model Inline6
  function f
    input Real x;
    output Real y;
  algorithm
    if x <= 1 then
      if x <= 0 then
        y := 0;
      else
        y := 1;
      end if;
    else
      y := 3;
    end if;
  end f;

  Real x = 1;
  Real y = f(x);
  annotation(__OpenModelica_commandLineOptions="-f --baseModelicaOptions=inlineFunctions");
end Inline6;

// Result:
// //! base 0.1.0
// package 'Inline6'
//   model 'Inline6'
//     Real 'x' = 1.0;
//     Real 'y' = if 'x' <= 1.0 then if 'x' <= 0.0 then 0.0 else 1.0 else 3.0;
//   end 'Inline6';
// end 'Inline6';
// endResult
