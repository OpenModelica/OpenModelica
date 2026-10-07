// name: ProtectedAccess
// keywords: protected, access
// status: correct
//
// Tests that we give a warning when accessing protected elements of another class
//

model TestModel
protected
  Integer x = 2;
end TestModel;

model ProtectedAccess
  TestModel tm(x = 3);
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end ProtectedAccess;


// Result:
// class ProtectedAccess
//   protected Integer tm.x = 3;
// end ProtectedAccess;
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
//
// endResult
