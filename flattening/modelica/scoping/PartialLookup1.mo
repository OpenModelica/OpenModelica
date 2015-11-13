// name:     PartialLookup1
// keywords: lookup partial redeclare
// status:   correct
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
// class PartialLookup1
// end PartialLookup1;
// [flattening/modelica/scoping/PartialLookup1.mo:13:3-13:8:writable] Error: P is partial, name lookup is not allowed in partial classes.
//
// endResult
