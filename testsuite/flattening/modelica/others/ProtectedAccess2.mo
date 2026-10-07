// name: ProtectedAccess2
// keywords: protected, access
// status: correct
//
// Tests access to protected elements of another class
// THIS TEST SHOULD FAIL!
//

model TestModel
protected
  Integer x = 2;
end TestModel;

model ProtectedAccess2
  TestModel tm;
equation
  tm.x = 3;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end ProtectedAccess2;

// Result:
// class ProtectedAccess2
//   protected Integer tm.x = 2;
// equation
//   tm.x = 3;
// end ProtectedAccess2;
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
//
// endResult
