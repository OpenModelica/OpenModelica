// name: ArrayCurlyBrackets
// keywords: array
// status: correct
//
// Tests array construction with curly bracket syntax
//

model ArrayCurlyBrackets
  Integer intArray[7];
equation
  intArray = { 1, 2, 3, 4, 5, 6, 7 };
end ArrayCurlyBrackets;

// Result:
// class ArrayCurlyBrackets
//   Integer intArray[1];
//   Integer intArray[2];
//   Integer intArray[3];
//   Integer intArray[4];
//   Integer intArray[5];
//   Integer intArray[6];
//   Integer intArray[7];
// equation
//   intArray[1] = 1;
//   intArray[2] = 2;
//   intArray[3] = 3;
//   intArray[4] = 4;
//   intArray[5] = 5;
//   intArray[6] = 6;
//   intArray[7] = 7;
// end ArrayCurlyBrackets;
// endResult
