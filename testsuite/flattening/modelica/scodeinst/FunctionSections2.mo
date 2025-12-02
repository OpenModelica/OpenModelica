// name: FunctionSections2
// keywords:
// status: incorrect
//
//

partial function base_f
  input Real x;
  output Real y;
algorithm
  y := x;
end base_f;

function f
  extends base_f;
algorithm
  x := y;
end f;

model FunctionSections2
  Real x = f(time);
end FunctionSections2;

// Result:
// Error processing file: FunctionSections2.mo
// [flattening/modelica/scodeinst/FunctionSections2.mo:14:1-18:6:writable] Error: Function f has more than one algorithm section or external declaration.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
