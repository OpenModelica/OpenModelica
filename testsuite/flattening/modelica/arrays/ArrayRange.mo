// name: ArrayRange
// keywords: array, range
// status: correct
//
// tests construction of arrays with range initialization
//

model ArrayRange
  Integer intArray[7,1];
equation
  intArray = [1:2:14];
end ArrayRange;

// Result:
// class ArrayRange
//   Integer intArray[1,1];
//   Integer intArray[2,1];
//   Integer intArray[3,1];
//   Integer intArray[4,1];
//   Integer intArray[5,1];
//   Integer intArray[6,1];
//   Integer intArray[7,1];
// equation
//   intArray[1,1] = 1;
//   intArray[2,1] = 3;
//   intArray[3,1] = 5;
//   intArray[4,1] = 7;
//   intArray[5,1] = 9;
//   intArray[6,1] = 11;
//   intArray[7,1] = 13;
// end ArrayRange;
// endResult
