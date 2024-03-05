// name: UnboundParameter1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model UnboundParameter1
  parameter Real x;
end UnboundParameter1;

// Result:
// Error processing file: UnboundParameter1.mo
// [flattening/modelica/scodeinst/UnboundParameter1.mo:8:3-8:19:writable] Error: Parameter x has neither value nor start value, and is fixed during initialization (fixed=true).
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
