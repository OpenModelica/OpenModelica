// name: ceval4.mo
// status: correct
// cflags: -d=newInst

model A
  function f
    input Integer i;
    output Integer j=i+1;
  end f;

  parameter Integer n = 1;
  parameter Integer m = f(n)+n;
  Real x[m] = {1.0, 1.0, 1.0}; //fill(1.0, m);
end A;

// Result:
// [OpenModelica/OMCompiler/Compiler/NFFrontEnd/NFSimplifyExp.mo:164:9-164:105:writable]Modelica Assert: Unimplemented case for f(1) in NFSimplifyExp.postSimplify!
// Error processing file: ceval4.mo
// Error: Internal error Instantiation of A failed with no error message.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
