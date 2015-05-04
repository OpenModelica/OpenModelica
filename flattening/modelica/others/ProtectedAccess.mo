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
end ProtectedAccess;


// Result:
// class ProtectedAccess
//   protected Integer tm.x = 3;
// end ProtectedAccess;
// endResult
