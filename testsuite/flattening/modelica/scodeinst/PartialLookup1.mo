// name: PartialLookup1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

partial package P
  model A
    Real x;
  end A;
end P;

class PartialLookup1
  P.A a;
end PartialLookup1;

// Result:
// Error processing file: PartialLookup1.mo
// [flattening/modelica/scodeinst/PartialLookup1.mo:14:3-14:8:writable] Error: P is partial, name lookup is not allowed in partial classes.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
