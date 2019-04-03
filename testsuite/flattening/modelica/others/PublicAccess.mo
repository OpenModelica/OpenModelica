// name: PublicAccess
// keywords: public, access
// status: correct
//
// Tests access to public elements of another class
//

model TestModel
public
  Integer x = 2;
end TestModel;

model PublicAccess
  TestModel tm;
equation
  tm.x = 3;
end PublicAccess;

// Result:
// class PublicAccess
//   Integer tm.x = 2;
// equation
//   tm.x = 3;
// end PublicAccess;
// endResult
