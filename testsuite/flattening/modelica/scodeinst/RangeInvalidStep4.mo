// name: RangeInvalidStep4.mo
// keywords:
// status: incorrect
// cflags: -d=newInst
//
// Check that a step size close to 0 isn't allowed, since that would give an
// infinite range.
// 

model RangeInvalidStep4
  Real x[10] = 1:1e-300:10;
end RangeInvalidStep4;

// Result:
// Error processing file: RangeInvalidStep4.mo
// [flattening/modelica/scodeinst/RangeInvalidStep4.mo:11:3-11:27:writable] Error: Step size 1e-300 in range is too small.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
