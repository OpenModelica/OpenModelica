// name:     ArrayMult
// keywords: array
// status:   correct
//
// Array multiplication
// Drmodelica: 7.6 Arithmetic Array Operators (p. 223)
// cflags: -d=-newInst
//
class ArrayMult
  Real m1[3] = {1, 2, 3} * 2;       // Elementwise mult: {2, 4, 6};
  Real m2[3] = 3 * {1, 2, 3};       // Elementwise mult: {3, 6, 9};
  Real m3 = {1, 2, 3} * {1, 2, 2};     // Scalar product:    11;
  Real m4[2] = {{1, 2}, {3, 4}} * {1, 2};   // Matrix mult:    {5, 11};
  Real m5[1] = {1, 2, 3} * {{1}, {2}, {10}};    // Matrix mult:    {35};
  Real m6[1] = {1, 2, 3} * [1; 2; 10];       // Matrix mult:     {35};
  Real m7[2, 2] = {{1, 2}, {3, 4}} * {{1, 2}, {2, 1}};   // Matrix mult:   {{5, 4}, {11, 10}};
  Real m8[2, 2] = [1, 2; 3, 4] * [1, 2; 2, 1];   // Matrix mult: {{5, 4}, {11, 10}};
end ArrayMult;

// class ArrayMult
// Real m1[1];
// Real m1[2];
// Real m1[3];
// Real m2[1];
// Real m2[2];
// Real m2[3];
// Real m3;
// Real m4[1];
// Real m4[2];
// Real m5[1];
// Real m6[1];
// Real m7[1,1];
// Real m7[1,2];
// Real m7[2,1];
// Real m7[2,2];
// Real m8[1,1];
// Real m8[1,2];
// Real m8[2,1];
// Real m8[2,2];
// equation
//   m1[1] = 2.0;
//   m1[2] = 4.0;
//   m1[3] = 6.0;
//   m2[1] = 3.0;
//   m2[2] = 6.0;
//   m2[3] = 9.0;
//   m3 = 11.0;
//   m4[1] = 5.0;
//   m4[2] = 11.0;
//   m5[1] = 35.0;
//   m6[1] = 35.0;
//   m7[1,1] = 5.0;
//   m7[1,2] = 4.0;
//   m7[2,1] = 11.0;
//   m7[2,2] = 10.0;
//   m8[1,1] = 5.0;
//   m8[1,2] = 4.0;
//   m8[2,1] = 11.0;
//   m8[2,2] = 10.0;
// end ArrayMult;
