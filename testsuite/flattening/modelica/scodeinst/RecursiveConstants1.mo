// name: RecursiveConstants1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model RecursiveConstants1
  constant Real x = y;
  constant Real y = x;
end RecursiveConstants1;

// Result:
// Error processing file: RecursiveConstants1.mo
// [flattening/modelica/scodeinst/RecursiveConstants1.mo:9:3-9:22:writable] Error: Variable 'y' has a cyclic dependency and has variability constant.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
