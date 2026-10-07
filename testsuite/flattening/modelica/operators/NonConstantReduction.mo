// name:     NonConstantReduction
// keywords: array
// status:   correct
//
// Tests elaboration of non-constant reductions.
//

class NonConstantReduction
  Integer i = min(i for i in {1 + integer(time)});
end NonConstantReduction;

// Result:
// class NonConstantReduction
//   Integer i = 1 + integer(time);
// end NonConstantReduction;
// [flattening/modelica/operators/NonConstantReduction.mo:9:3-9:50:writable] Warning: Components are deprecated in class.
//
// endResult
