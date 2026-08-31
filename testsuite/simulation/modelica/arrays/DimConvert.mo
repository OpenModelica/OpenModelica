// name:     DimConvert
// keywords: array
// status:   correct
//
// Drmodelica: 7.7 Built-in Functions (p. 225)
//

class DimConvert
  Real[3] v1 =      {1.0, 2.0, 3.0};
  Real[3,1] m1 =    matrix(v1);     // m1 contains {{1.0}, {2.0}, {3.0}}
  Real[3] v2 =      vector(m1);     // v2 contains {1.0, 2.0, 3.0}

  Real[1,1,1] m2 =  {{{4}}};
  Real s1 =         scalar(m2);     // s1 contains 4.0
  Real[2,2,1] m3 =  {{{1.0}, {2.0}}, {{3.0}, {4.0}}};
  Real[2,2] m4 =    matrix(m3);     // m4 contains {{1.0, 2.0}, {3.0, 4.0}}
end DimConvert;

// Result:
// class DimConvert
//   Real v1[1] = 1.0;
//   Real v1[2] = 2.0;
//   Real v1[3] = 3.0;
//   Real m1[1,1] = v1[1];
//   Real m1[2,1] = v1[2];
//   Real m1[3,1] = v1[3];
//   Real v2[1] = m1[1,1];
//   Real v2[2] = m1[2,1];
//   Real v2[3] = m1[3,1];
//   Real m2[1,1,1] = 4.0;
//   Real s1 = m2[1,1,1];
//   Real m3[1,1,1] = 1.0;
//   Real m3[1,2,1] = 2.0;
//   Real m3[2,1,1] = 3.0;
//   Real m3[2,2,1] = 4.0;
//   Real m4[1,1] = m3[1,1,1];
//   Real m4[1,2] = m3[1,2,1];
//   Real m4[2,1] = m3[2,1,1];
//   Real m4[2,2] = m3[2,2,1];
// end DimConvert;
// endResult
