// name:     EmptyAsubSliceSubscript
// keywords: asub slice subscript array #3219
// status:   correct
//
// Checks that the compiler can handle asubs of empty array being used as
// subscripts.
//

model EmptyAsubSliceSubscript
  Integer arr[0] = zeros(0);
  Integer n = 0;
algorithm
  arr := arr[arr[1:n]];
end EmptyAsubSliceSubscript;

// Result:
// class EmptyAsubSliceSubscript
//   Integer n = 0;
// algorithm
//   arr := {}[{}[1:n]];
// end EmptyAsubSliceSubscript;
// endResult
