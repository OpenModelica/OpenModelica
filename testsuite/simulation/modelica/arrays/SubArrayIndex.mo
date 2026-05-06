// name:     SubArrayIndex
// keywords: <insert keywords here>
// status:   correct
//
// MORE WORK HAS TO BE DONE ON THIS FILE!
//
// Drmodelica: 7.4 Array Indexing operator (p. 216)
//
class SubArrayIndex
  Real[2, 2] B = {{1, 2}, {4, 5}};
  Real[2] v = {10, 11};
  Real[4, 2] M;
  Real B_Ret1 = B[1, 2]; // Retrieves the value 2
  //Real B_Ret2[2] = B[2]; // Retrieves B[2] giving {4, 5}
  Real v_Ret1 = v[2]; // Retrieves the value 11
  // Real v_Ret2 = v[4]; // Error, index out of range!
algorithm
  M[4] := fill(5, 4, 2);
  M[4] := v; // Updates M to become
  // {{5, 5}, {5, 5},{5, 5}, {10, 11}}
end SubArrayIndex;

// insert expected flat file here. Can be done by issuing the command
// ./omc XXX.mo >> XXX.mo and then comment the inserted class.
//
// class <XXX>
// Real x;
// end <XXX>;
