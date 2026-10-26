// name: ArrayAccess
// keywords: array
// status: correct
//
// Testing simple array access
//

model ArrayAccess
  Integer intArray1[3];
  Integer intArray2[3];
equation
  intArray1 = {1, 2, 3};
  intArray2[1] = intArray1[1];
  intArray2[2] = intArray1[2];
  intArray2[3] = intArray1[3];
end ArrayAccess;

// Result:
// class ArrayAccess
//   Integer intArray1[1];
//   Integer intArray1[2];
//   Integer intArray1[3];
//   Integer intArray2[1];
//   Integer intArray2[2];
//   Integer intArray2[3];
// equation
//   intArray1[1] = 1;
//   intArray1[2] = 2;
//   intArray1[3] = 3;
//   intArray2[1] = intArray1[1];
//   intArray2[2] = intArray1[2];
//   intArray2[3] = intArray1[3];
// end ArrayAccess;
// endResult
