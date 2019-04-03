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
end ProtectedAccess2;

// Result:
// class ProtectedAccess2
//   protected Integer tm.x = 2;
// equation
//   tm.x = 3;
// end ProtectedAccess2;
// endResult
