// name: RangeInvalidStep3.mo
// keywords:
// status: incorrect
// cflags: -d=newInst
//
// Checks that an enumeration range isn't allowed to have a step size.
// 

model RangeInvalidStep3
  type E = enumeration(one, two, three);
  E x[3] = E.one:E.one:E.three;
end RangeInvalidStep3;

// Result:
// Error processing file: RangeInvalidStep3.mo
// [flattening/modelica/scodeinst/RangeInvalidStep3.mo:11:3-11:31:writable] Error: Range of type enumeration E(one, two, three) may not specify a step size.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
