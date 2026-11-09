// name: ArrayBrackets
// keywords: array
// status: correct
//
// tests array construction with bracket syntax
//

model ArrayBrackets
  Integer intArray[1,7];
equation
  intArray = [1, 2, 3, 4, 5, 6, 7];
end ArrayBrackets;

// Result:
// class ArrayBrackets
//   Integer intArray[1,1];
//   Integer intArray[1,2];
//   Integer intArray[1,3];
//   Integer intArray[1,4];
//   Integer intArray[1,5];
//   Integer intArray[1,6];
//   Integer intArray[1,7];
// equation
//   intArray[1,1] = 1;
//   intArray[1,2] = 2;
//   intArray[1,3] = 3;
//   intArray[1,4] = 4;
//   intArray[1,5] = 5;
//   intArray[1,6] = 6;
//   intArray[1,7] = 7;
// end ArrayBrackets;
// endResult
