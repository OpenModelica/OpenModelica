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
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end PartialLookup1;

// Result:
// class PartialLookup1
// end PartialLookup1;
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
// [flattening/modelica/scoping/PartialLookup1.mo:13:3-13:8:writable] Error: P is partial, name lookup is not allowed in partial classes.
//
// endResult
