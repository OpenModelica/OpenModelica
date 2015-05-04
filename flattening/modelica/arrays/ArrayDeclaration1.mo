// name: ArrayDeclaration1
// keywords: array
// status: correct
//
// Tests array declaration of the form Type[dim] identifier;
//

model ArrayDeclaration1
  Real[2] realArray;
equation
  realArray[1] = 4;
  realArray[2] = 5;
end ArrayDeclaration1;

// Result:
// class ArrayDeclaration1
//   Real realArray[1];
//   Real realArray[2];
// equation
//   realArray[1] = 4.0;
//   realArray[2] = 5.0;
// end ArrayDeclaration1;
// endResult
