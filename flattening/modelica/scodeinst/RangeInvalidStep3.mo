// name: RangeInvalidStep3.mo
// keywords:
// status: incorrect
// cflags: -d=newInst
//
// Check that a step size close to 0 isn't allowed, since that would give an
// infinite range.
// 

model RangeInvalidStep3
  type E = enumeration(one, two, three);
  E x[3] = E.one:E.one:E.three;
end RangeInvalidStep3;

// Result:
// Error processing file: RangeInvalidStep3.mo
// [flattening/modelica/scodeinst/RangeInvalidStep3.mo:12:3-12:31:writable] Error: Range of type enumeration() may not specify a step size.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
