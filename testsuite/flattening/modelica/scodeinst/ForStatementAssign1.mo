// name: ForStatementAssign1
// keywords:
// status: incorrect
// cflags: -d=newInst
//
//

model ForStatementAssign1
algorithm
  for i in 1:2 loop
    i := 1;
  end for;
end ForStatementAssign1;

// Result:
// Error processing file: ForStatementAssign1.mo
// [flattening/modelica/scodeinst/ForStatementAssign1.mo:11:5-11:11:writable] Error: Assignment to iterator 'i'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
