// name: RedeclareElementMissing2
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model RedeclareElementMissing2
  redeclare model A
    Real x;
  end A;
end RedeclareElementMissing2;  

// Result:
// Error processing file: RedeclareElementMissing2.mo
// [flattening/modelica/scodeinst/RedeclareElementMissing2.mo:8:13-10:8:writable] Error: Illegal redeclare of element A, no inherited element with that name exists.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
