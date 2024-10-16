// name:     ScalarizeBindings
// keywords: declaration scalarization
// status:   correct
//
// Checks that array bindings are scalarized when the +scalarizeBindings flag is
// used.
//

class ScalarizeBindings
  Real x[3] = {1, 2, 3};
  annotation(__OpenModelica_commandLineOptions="+scalarizeBindings -d=-newInst");
end ScalarizeBindings;

// Result:
// class ScalarizeBindings
//   Real x[1] = 1.0;
//   Real x[2] = 2.0;
//   Real x[3] = 3.0;
// end ScalarizeBindings;
// endResult
