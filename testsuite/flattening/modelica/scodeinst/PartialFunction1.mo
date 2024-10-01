// name: PartialFunction1
// keywords:
// status: incorrect
//

partial function f
  input Real x;
  output Real y;
end f;

model PartialFunction1
  Real x = f(time);
end PartialFunction1;

// Result:
// Error processing file: PartialFunction1.mo
// [flattening/modelica/scodeinst/PartialFunction1.mo:12:3-12:19:writable] Error: Called function 'f' is partial.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
