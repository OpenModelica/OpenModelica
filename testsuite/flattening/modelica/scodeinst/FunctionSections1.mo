// name: FunctionSections1
// keywords:
// status: incorrect
//
//

function f
  input Real x;
  output Real y;
algorithm
  y := x;
algorithm
  y := x;
end f;

model FunctionSections1
  Real x = f(time);
end FunctionSections1;

// Result:
// Error processing file: FunctionSections1.mo
// [flattening/modelica/scodeinst/FunctionSections1.mo:7:1-14:6:writable] Error: Function f has more than one algorithm section or external declaration.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
