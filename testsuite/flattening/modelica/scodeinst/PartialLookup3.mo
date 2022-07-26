// name:     PartialLookup3
// keywords: lookup partial redeclare
// status:   incorrect
// cflags: -d=newInst
//
// Checks that it's not allowed to look up a name in a partial class.
//

package P
  partial package P2
      model A
        Real x;
      end A;
  end P2;
end P;

model PartialLookup3
  extends P.P2.A;
end PartialLookup3;

// Result:
// Error processing file: PartialLookup3.mo
// [flattening/modelica/scodeinst/PartialLookup3.mo:18:3-18:17:writable] Error: P2 is partial, name lookup is not allowed in partial classes.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
