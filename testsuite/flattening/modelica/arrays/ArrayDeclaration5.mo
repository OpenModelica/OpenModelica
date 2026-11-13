// name: ArrayDeclaration5
// keywords: array
// status: correct
//
// Tests declaring arrays with unspecified dimensions
//

model ArrayDeclaration5
  Real realArray[:] = {1,2,3,4};
end ArrayDeclaration5;

// Result:
// class ArrayDeclaration5
//   Real realArray[1];
//   Real realArray[2];
//   Real realArray[3];
//   Real realArray[4];
// equation
//   realArray = {1.0, 2.0, 3.0, 4.0};
// end ArrayDeclaration5;
// endResult
