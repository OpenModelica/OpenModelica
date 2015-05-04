// name:     SimpleIntegrator3
// keywords: declaration,equation
// status:   incorrect
//
// Cannot specify predefined attribute in an equation section,
// since parameters must be bound by modifiers.

model SimpleIntegrator3
  Real u = 1.0;
  Real x;
equation
  x.start = 2.0;
  der(x) = u;
end SimpleIntegrator3;
// Result:
// Error processing file: SimpleIntegrator3.mo
// [flattening/modelica/declarations/SimpleIntegrator3.mo:12:3-12:16:writable] Error: Variable x.start not found in scope SimpleIntegrator3.
// Error: Error occurred while flattening model SimpleIntegrator3
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
