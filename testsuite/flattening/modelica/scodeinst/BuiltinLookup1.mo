// name: BuiltinLookup1
// keywords:
// status: incorrect
//

model BuiltinLookup1
  model Boolean
    Real x;
  end Boolean;

  Real y = Boolean.x;
end BuiltinLookup1;

// Result:
// Error processing file: BuiltinLookup1.mo
// [flattening/modelica/scodeinst/BuiltinLookup1.mo:11:3-11:21:writable] Error: Variable Boolean.x not found in scope BuiltinLookup1.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
