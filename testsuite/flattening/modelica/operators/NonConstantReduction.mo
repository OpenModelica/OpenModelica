// name:     NonConstantReduction
// keywords: array
// status:   correct
//
// Tests elaboration of non-constant reductions.
//

class NonConstantReduction
  Integer i = min(i for i in {1 + integer(time)});
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end NonConstantReduction;

// Result:
// class NonConstantReduction
//   Integer i = 1 + integer(time);
// end NonConstantReduction;
// endResult
