// name: for3.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
//

model A
  Real x;
equation
  for i in 1 loop
    x = x;
  end for;
end A;

// Result:
// Error processing file: for3.mo
// [flattening/modelica/scodeinst/for3.mo:10:3-12:10:writable] Error: Type error in iteration range '1'. Expected array got Integer.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
