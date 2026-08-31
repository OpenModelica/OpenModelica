// name: ImplicitTrailingSubscript1
// keywords: array subscript implicit trailing
// status: correct
//
// Scalar index on a 2D array is implicitly adding trailing ':' subscripts.
// Explicitly add them to only have one canonical form for arrays.

function testFunc
  input Real oldArray[3, 2];
  output Real newArray[3, 2];
algorithm
  for i in 1:3 loop
    newArray[i] := oldArray[i];
  end for;
end testFunc;

model ImplicitTrailingSubscript1
  Real a[3, 2];
  Real b[3, 2];
equation
  b = testFunc(a);
end ImplicitTrailingSubscript1;

// Result:
// function testFunc
//   input Real[3, 2] oldArray;
//   output Real[3, 2] newArray;
// algorithm
//   for i in 1:3 loop
//     newArray[i,:] := oldArray[i,:];
//   end for;
// end testFunc;
//
// class ImplicitTrailingSubscript1
//   Real a[1,1];
//   Real a[1,2];
//   Real a[2,1];
//   Real a[2,2];
//   Real a[3,1];
//   Real a[3,2];
//   Real b[1,1];
//   Real b[1,2];
//   Real b[2,1];
//   Real b[2,2];
//   Real b[3,1];
//   Real b[3,2];
// equation
//   b = testFunc(a);
// end ImplicitTrailingSubscript1;
// endResult
