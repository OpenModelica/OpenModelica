// name: AssertInvalid4
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model AssertInvalid4
  AssertionLevel level = AssertionLevel.warning;
equation
  assert(time > 2, "message", level);
end AssertInvalid4;

// Result:
// Error processing file: AssertInvalid4.mo
// [flattening/modelica/scodeinst/AssertInvalid4.mo:10:3-10:37:writable] Error: Function argument level=level in call to assert has variability discrete which is not a parameter expression.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
