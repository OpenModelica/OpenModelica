// name: ForStatementNonVector.mo
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model ForStatementNonVector
  Real x;
equation
  for i in 1 loop
    x = x;
  end for;
end ForStatementNonVector;

// Result:
// Error processing file: ForStatementNonVector.mo
// [flattening/modelica/scodeinst/ForStatementNonVector.mo:10:3-12:10:writable] Error: Type error in iteration range '1'. Expected array got Integer.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
