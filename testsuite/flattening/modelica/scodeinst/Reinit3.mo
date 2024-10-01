// name: Reinit3
// keywords:
// status: correct
//

model Reinit3
  Real x;
algorithm
  when time > 1 then
    reinit(x, 2);
  end when;
  annotation(__OpenModelica_commandLineOptions="--allowNonStandardModelica=reinitInAlgorithms");
end Reinit3;

// Result:
// class Reinit3
//   Real x;
// algorithm
//   when time > 1.0 then
//     reinit(x, 2.0);
//   end when;
// end Reinit3;
// endResult
