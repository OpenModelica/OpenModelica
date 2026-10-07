// name:     Skew
// keywords: skew
// status:   correct
//
// Tests the builtin skew function.
//

model Skew
  input Real rv[3];
  output Real rm[3,3];
equation
  rm = skew(rv);
end Skew;

// Result:
// class Skew
//   input Real rv[1];
//   input Real rv[2];
//   input Real rv[3];
//   output Real rm[1,1];
//   output Real rm[1,2];
//   output Real rm[1,3];
//   output Real rm[2,1];
//   output Real rm[2,2];
//   output Real rm[2,3];
//   output Real rm[3,1];
//   output Real rm[3,2];
//   output Real rm[3,3];
// equation
//   rm[1,1] = 0.0;
//   rm[1,2] = -rv[3];
//   rm[1,3] = rv[2];
//   rm[2,1] = rv[3];
//   rm[2,2] = 0.0;
//   rm[2,3] = -rv[1];
//   rm[3,1] = -rv[2];
//   rm[3,2] = rv[1];
//   rm[3,3] = 0.0;
// end Skew;
// endResult
