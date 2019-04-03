// name: Symmetric3
// keywords: symmetric
// status: correct
//
// Tests the built-in symmetric function
//

model Symmetric3
  parameter Real m[4,4] = [1,2,3,4;4,3,2,1;5,6,7,8;8,7,6,5];
  Real sym[4,4];
equation
  sym = symmetric(m);
end Symmetric3;

// Result:
// class Symmetric3
//   parameter Real m[1,1] = 1.0;
//   parameter Real m[1,2] = 2.0;
//   parameter Real m[1,3] = 3.0;
//   parameter Real m[1,4] = 4.0;
//   parameter Real m[2,1] = 4.0;
//   parameter Real m[2,2] = 3.0;
//   parameter Real m[2,3] = 2.0;
//   parameter Real m[2,4] = 1.0;
//   parameter Real m[3,1] = 5.0;
//   parameter Real m[3,2] = 6.0;
//   parameter Real m[3,3] = 7.0;
//   parameter Real m[3,4] = 8.0;
//   parameter Real m[4,1] = 8.0;
//   parameter Real m[4,2] = 7.0;
//   parameter Real m[4,3] = 6.0;
//   parameter Real m[4,4] = 5.0;
//   Real sym[1,1];
//   Real sym[1,2];
//   Real sym[1,3];
//   Real sym[1,4];
//   Real sym[2,1];
//   Real sym[2,2];
//   Real sym[2,3];
//   Real sym[2,4];
//   Real sym[3,1];
//   Real sym[3,2];
//   Real sym[3,3];
//   Real sym[3,4];
//   Real sym[4,1];
//   Real sym[4,2];
//   Real sym[4,3];
//   Real sym[4,4];
// equation
//   sym[1,1] = m[1,1];
//   sym[1,2] = m[1,2];
//   sym[1,3] = m[1,3];
//   sym[1,4] = m[1,4];
//   sym[2,1] = m[1,2];
//   sym[2,2] = m[2,2];
//   sym[2,3] = m[2,3];
//   sym[2,4] = m[2,4];
//   sym[3,1] = m[1,3];
//   sym[3,2] = m[2,3];
//   sym[3,3] = m[3,3];
//   sym[3,4] = m[3,4];
//   sym[4,1] = m[1,4];
//   sym[4,2] = m[2,4];
//   sym[4,3] = m[3,4];
//   sym[4,4] = m[4,4];
// end Symmetric3;
// endResult
