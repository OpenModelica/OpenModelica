// name: UnboundParameter1
// keywords:
// status: incorrect
//

model UnboundParameter1
  parameter Real x;
end UnboundParameter1;

// Result:
// Error processing file: UnboundParameter1.mo
// [flattening/modelica/scodeinst/UnboundParameter1.mo:7:3-7:19:writable] Error: Parameter x has neither binding nor start value, and is fixed during initialization (fixed=true).
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
