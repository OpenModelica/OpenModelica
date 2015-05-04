// name: ArrayExtend
// keywords: array, inheritance
// status: correct
//
// Tests extension of types that are declared as arrays
// Makes sure you can't combine them with simple components
// THIS TEST SHOULD FAIL
//

model TestModel
  Real r;
end TestModel;

model TestModels = TestModel[3];

model ArrayExtend
  extends TestModels;
  Real illegalReal;
end ArrayExtend;

// Result:
// class ArrayExtend
//   Real r;
//   Real illegalReal;
// end ArrayExtend;
// endResult
