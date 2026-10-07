// name:     ScalarizeBindings
// keywords: declaration scalarization
// status:   correct
//
// Checks that array bindings are scalarized when the +scalarizeBindings flag is
// used.
//

class ScalarizeBindings
  Real x[3] = {1, 2, 3};
  annotation(__OpenModelica_commandLineOptions="+scalarizeBindings");
end ScalarizeBindings;

// Result:
// class ScalarizeBindings
//   Real x[1];
//   Real x[2];
//   Real x[3];
// equation
//   x = {1.0, 2.0, 3.0};
// end ScalarizeBindings;
// [flattening/modelica/declarations/ScalarizeBindings.mo:10:3-10:24:writable] Warning: Components are deprecated in class.
//
// endResult
