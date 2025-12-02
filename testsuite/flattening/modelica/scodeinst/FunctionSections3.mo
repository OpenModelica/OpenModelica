// name: FunctionSections3
// keywords:
// status: incorrect
//
//

function f
  input Real x;
  output Real y;
algorithm
  y := x;
external "C";
end f;

model FunctionSections3
  Real x = f(time);
end FunctionSections3;

// Result:
// Error processing file: FunctionSections3.mo
// [flattening/modelica/scodeinst/FunctionSections3.mo:7:1-13:6:writable] Error: Function f has more than one algorithm section or external declaration.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
