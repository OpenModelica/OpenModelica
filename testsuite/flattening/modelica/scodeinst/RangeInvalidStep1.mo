// name: RangeInvalidStep1.mo
// keywords:
// status: incorrect
// cflags: -d=newInst
//
// Check that a step size of 0 isn't allowed, since that would give an infinite
// range.
// 

model RangeInvalidStep1
  Real x[10] = 1:0:10;
end RangeInvalidStep1;

// Result:
// Error processing file: RangeInvalidStep1.mo
// [flattening/modelica/scodeinst/RangeInvalidStep1.mo:11:3-11:22:writable] Error: Step size 0 in range is too small.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
