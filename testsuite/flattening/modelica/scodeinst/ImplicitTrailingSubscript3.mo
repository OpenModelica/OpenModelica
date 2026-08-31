// name: ImplicitTrailingSubscript3
// keywords: array subscript implicit trailing
// status: correct
//
// Index on a 2D array is implicitly adding trailing ':' subscripts.
// Explicitly add them to only have one canonical form for arrays.

function initFunc
  input Real oldArray[3, 2];
  output Real newArray[3, 2];
algorithm
  newArray[1:2] := oldArray[2:3];
  newArray[3] := {0,0};
end initFunc;

model ImplicitTrailingSubscript3
  Real a[3, 2] = fill({1,2}, 3);
  Real b[3, 2] = initFunc(a);
end ImplicitTrailingSubscript3;

// Result:
// function initFunc
//   input Real[3, 2] oldArray;
//   output Real[3, 2] newArray;
// algorithm
//   newArray[1:2,:] := oldArray[2:3,:];
//   newArray[3,:] := {0.0, 0.0};
// end initFunc;
//
// class ImplicitTrailingSubscript3
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
//   a = {{1.0, 2.0}, {1.0, 2.0}, {1.0, 2.0}};
//   b = initFunc(a);
// end ImplicitTrailingSubscript3;
// endResult
