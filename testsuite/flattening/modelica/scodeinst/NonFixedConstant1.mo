// name: NonFixedConstant1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model NonFixedConstant1
  constant Real x(fixed = false) = 1.0;
end NonFixedConstant1;

// Result:
// Error processing file: NonFixedConstant1.mo
// [flattening/modelica/scodeinst/NonFixedConstant1.mo:8:3-8:39:writable] Error: Constant 'x' must be fixed but has 'fixed = false'
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
