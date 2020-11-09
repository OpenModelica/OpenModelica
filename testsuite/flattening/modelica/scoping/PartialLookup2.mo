// name:     PartialLookup2
// keywords: lookup partial redeclare
// status:   incorrect
// cflags: -d=-newInst
//
// Checks that it's not allowed to look up a name in a partial class.
//

model A
  partial package PP
    model B end B;
  end PP;

  PP.B b;
end A;

model PartialLookup2
  A a;
end PartialLookup2;

// Result:
// Error processing file: PartialLookup2.mo
// [flattening/modelica/scoping/PartialLookup2.mo:10:3-12:9:writable] Notification: From here:
// [flattening/modelica/scoping/PartialLookup2.mo:18:3-18:6:writable] Error: component a contains the definition of a partial class PP.
// Please redeclare it to any package compatible with A.PP.
// Error: Error occurred while flattening model PartialLookup2
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
