// name: lookup2.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
//

model A
  model B
    model C
      Real x;
    end C;
  end B;

  B b;
end A;

model M
  A a;
  A.b.C c;
end M;

// Result:
// Error processing file: lookup2.mo
// [flattening/modelica/scodeinst/lookup2.mo:19:3-19:10:writable] Error: Class name 'A.b.C' was found via a component (only component and function call names may be accessed in this way).
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
