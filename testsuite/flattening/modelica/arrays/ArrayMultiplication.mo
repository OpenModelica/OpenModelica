// name: ArrayMultiplication
// keywords: array, multiplication
// status: correct
//
// Tests elementwise array multiplication
//

model ArrayMultiplication
  constant Integer intArray1[3] = {4, 8, 12};
  constant Integer intArray2[3] = {2, 4, 6};
  Integer intArray[3];
equation
  intArray = intArray1 .* intArray2;
end ArrayMultiplication;

// Result:
// class ArrayMultiplication
//   constant Integer intArray1[1] = 4;
//   constant Integer intArray1[2] = 8;
//   constant Integer intArray1[3] = 12;
//   constant Integer intArray2[1] = 2;
//   constant Integer intArray2[2] = 4;
//   constant Integer intArray2[3] = 6;
//   Integer intArray[1];
//   Integer intArray[2];
//   Integer intArray[3];
// equation
//   intArray[1] = 8;
//   intArray[2] = 32;
//   intArray[3] = 72;
// end ArrayMultiplication;
// endResult
