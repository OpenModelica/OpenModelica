// name: ExtendSelf2.mo
// keywords:
// status: incorrect
//
// Checks that an extends loop gives an error.
//

model A
  extends ExtendSelf2;
end A;

model ExtendSelf2
  extends A;
end ExtendSelf2;

// Result:
// Error processing file: ExtendSelf2.mo
// [flattening/modelica/scodeinst/ExtendSelf2.mo:9:3-9:22:writable] Error: extends ExtendSelf2 causes an instantiation loop.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
