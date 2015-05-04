// name: ForNested
// keywords: for
// status: correct
//
// Tests a nested for loop
//

model ForNested
  Real rmatrix[4, 4];
algorithm
  for i in 1:4 loop
    for j in 1:4 loop
      rmatrix[i, j] := i * j;
    end for;
  end for;
end ForNested;

// Result:
// class ForNested
//   Real rmatrix[1,1];
//   Real rmatrix[1,2];
//   Real rmatrix[1,3];
//   Real rmatrix[1,4];
//   Real rmatrix[2,1];
//   Real rmatrix[2,2];
//   Real rmatrix[2,3];
//   Real rmatrix[2,4];
//   Real rmatrix[3,1];
//   Real rmatrix[3,2];
//   Real rmatrix[3,3];
//   Real rmatrix[3,4];
//   Real rmatrix[4,1];
//   Real rmatrix[4,2];
//   Real rmatrix[4,3];
//   Real rmatrix[4,4];
// algorithm
//   for i in 1:4 loop
//     for j in 1:4 loop
//       rmatrix[i,j] := /*Real*/(i * j);
//     end for;
//   end for;
// end ForNested;
// endResult
