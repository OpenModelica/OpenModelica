// name:     RangeVector
// keywords: <insert keywords here>
// status:   correct
//
// Drmodelica: 7.2  Array Constructor (p. 210)
//

model RangeVector
  constant Real v1[5] = 2.7 : 6.8; // v1 is {2.7, 3.7, 4.7, 5.7, 6.7}
  constant Real v2[5] = {2.7, 3.7, 4.7, 5.7, 6.7}; // v2 is equal to v1
  constant Integer v3[3] = 3 : 5; // v3 is {3, 4, 5}
  constant Integer v4empty[0] = 3 : 2; // v4empty is an empty Integer vector
  constant Real v5[4] = 1.0 : 2 : 8; // v5 is {1.0, 3.0, 5.0, 7.0}
  constant Integer v6[5] = 1 : -1 : -3; // v6 is {1, 0, -1, -2, -3}
  Real[0] v7none;  // v7 none is an empty Real vector
end RangeVector;

// Result:
// class RangeVector
//   constant Real v1[1] = 2.7;
//   constant Real v1[2] = 3.7;
//   constant Real v1[3] = 4.7;
//   constant Real v1[4] = 5.7;
//   constant Real v1[5] = 6.7;
//   constant Real v2[1] = 2.7;
//   constant Real v2[2] = 3.7;
//   constant Real v2[3] = 4.7;
//   constant Real v2[4] = 5.7;
//   constant Real v2[5] = 6.7;
//   constant Integer v3[1] = 3;
//   constant Integer v3[2] = 4;
//   constant Integer v3[3] = 5;
//   constant Real v5[1] = 1.0;
//   constant Real v5[2] = 3.0;
//   constant Real v5[3] = 5.0;
//   constant Real v5[4] = 7.0;
//   constant Integer v6[1] = 1;
//   constant Integer v6[2] = 0;
//   constant Integer v6[3] = -1;
//   constant Integer v6[4] = -2;
//   constant Integer v6[5] = -3;
// end RangeVector;
// endResult
