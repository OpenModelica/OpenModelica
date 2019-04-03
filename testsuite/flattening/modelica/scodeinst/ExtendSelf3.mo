// name: ExtendSelf3.mo
// keywords:
// status: incorrect
// cflags: -d=newInst
//
// Checks that a class extending from itself gives an error.
//

model ExtendSelf3
  extends ExtendSelf3;
end ExtendSelf3;

// Result:
// Error processing file: ExtendSelf3.mo
// [flattening/modelica/scodeinst/ExtendSelf3.mo:10:3-10:22:writable] Error: extends ExtendSelf3 causes an instantiation loop.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
