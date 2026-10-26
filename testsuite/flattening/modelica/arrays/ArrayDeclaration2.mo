// name: ArrayDeclaration2
// keywords: array
// status: correct
//
// Tests array declaration of the form Type[dim] identifier;
//

model ArrayDeclaration2
  Real realArray[2];
equation
  realArray[1] = 4;
  realArray[2] = 5;
end ArrayDeclaration2;

// Result:
// class ArrayDeclaration2
//   Real realArray[1];
//   Real realArray[2];
// equation
//   realArray[1] = 4.0;
//   realArray[2] = 5.0;
// end ArrayDeclaration2;
// endResult
