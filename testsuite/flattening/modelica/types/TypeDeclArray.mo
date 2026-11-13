// name: TypeDeclArray
// keywords: type, array
// status: correct
//
// Tests defining new types as arrays
//

type ArrayType = Real[3];

model TypeDeclArray
  ArrayType at;
equation
  at = {1,2,3};
end TypeDeclArray;

// Result:
// class TypeDeclArray
//   Real at[1];
//   Real at[2];
//   Real at[3];
// equation
//   at[1] = 1.0;
//   at[2] = 2.0;
//   at[3] = 3.0;
// end TypeDeclArray;
// endResult
