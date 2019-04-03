// name:     ArrayIndex
// keywords: <insert keywords here>
// status:   correct
//
// MORE WORK HAS TO BE DONE ON THIS FILE!
// Drmodelica: 7.4 Array Indexing operator (p. 216)
//

class ArrayIndex
  Real[2, 2] A = {{2, 3}, {4, 5}}; // Definition of array A
  Real A_Retrieval = A[2, 2]; // Retrieves the array element value 5
  Real B[2, 2];
  Real c;
algorithm
  B := fill(1,2,2); // B will have the values {{1, 1}, {1, 1}}
  B[2, 1] := 8; // Assignment to the array element B[2, 1]
  c := A[1, 1];
end ArrayIndex;

// insert expected flat file here. Can be done by issuing the command
// ./omc XXX.mo >> XXX.mo and then comment the inserted class.
//
// class ArrayIndex
// Real A[1,1];
// Real A[1,2];
// Real A[2,1];
// Real A[2,2];
// Real A_Retrieval;
// Real B[1,1];
// Real B[1,2];
// Real B[2,1];
// Real B[2,2];
// Real c;
// equation
//   A[1,1] = 2.0;
//   A[1,2] = 3.0;
//   A[2,1] = 4.0;
//   A[2,2] = 5.0;
//   A_Retrieval = A[2,2];
// algorithm
//   B := {{1.0,1.0},{1.0,1.0}};
//   B[2,1] := 8.0;
//   c := A[1,1];
// end ArrayIndex;
