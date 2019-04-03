// name:     DimConvert
// keywords: array
// status:   correct
//
// Not yet implemented
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
