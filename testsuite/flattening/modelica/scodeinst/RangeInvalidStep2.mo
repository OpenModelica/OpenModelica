// name: RangeInvalidStep2.mo
// keywords:
// status: incorrect
// cflags: -d=newInst
//
// Check that a step size of 0 isn't allowed, since that would give an infinite
// range.
// 

model RangeInvalidStep2
  Real x[10] = 1:0.0:10;
end RangeInvalidStep2;

// Result:
// Error processing file: RangeInvalidStep2.mo
// [flattening/modelica/scodeinst/RangeInvalidStep2.mo:11:3-11:24:writable] Error: Step size 0 in range is too small.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
