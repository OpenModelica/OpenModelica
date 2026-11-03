// name:     PartialLookup1
// keywords: lookup partial redeclare
// status:   incorrect
//
// Checks that it's not allowed to look up a name in a partial class.
//

model PartialLookup1
  partial package P
    model A end A;
  end P;

  P.A a;
end PartialLookup1;

// Result:
// Error processing file: PartialLookup1.mo
// [flattening/modelica/scoping/PartialLookup1.mo:13:3-13:8:writable] Error: P is partial, name lookup is not allowed in partial classes.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
