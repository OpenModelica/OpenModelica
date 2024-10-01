// name: TupleInvalid4
// keywords:
// status: incorrect
//

function f
  output Real x = 1.0;
  output Real y = 2.0;
end f;

model TupleInvalid4
  Real x;
  Real y;
equation
  (x + 1, y + 2) = f();
end TupleInvalid4;

// Result:
// Error processing file: TupleInvalid4.mo
// [flattening/modelica/scodeinst/TupleInvalid4.mo:15:3-15:23:writable] Error: Tuple assignment only allowed for tuple of component references in lhs (in (x + 1.0, y + 2.0)).
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
