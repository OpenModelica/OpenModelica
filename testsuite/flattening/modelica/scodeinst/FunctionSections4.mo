// name: FunctionSections4
// keywords:
// status: incorrect
//
//

partial function base_f
  input Real x;
  output Real y;
external "C";
end base_f;

function f
  extends base_f;
external "C";
end f;

model FunctionSections3
  Real x = f(time);
end FunctionSections3;

// Result:
// Error processing file: FunctionSections4.mo
// [flattening/modelica/scodeinst/FunctionSections4.mo:14:3-14:17:writable] Notification: From here:
// [flattening/modelica/scodeinst/FunctionSections4.mo:13:1-16:6:writable] Error: Function f has more than one algorithm section or external declaration.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
