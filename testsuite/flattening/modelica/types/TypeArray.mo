// name: TypeArray
// keywords: type, array
// status: correct
//
// Tests declaration of types from an array
//

type IntArray = Integer[3];

model TypeArray
  IntArray ia;
equation
  ia[1] = 1;
  ia[2] = 2;
  ia[3] = 3;
end TypeArray;

// Result:
// class TypeArray
//   Integer ia[1];
//   Integer ia[2];
//   Integer ia[3];
// equation
//   ia[1] = 1;
//   ia[2] = 2;
//   ia[3] = 3;
// end TypeArray;
// endResult
