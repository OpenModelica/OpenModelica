// name: Operators.mo
// keywords: operators
// status: correct
//
// Tests the different operators in the Modelica language
// Simple mathematical operations are tested in Expressions.mo
//

model OtherModel
  parameter Integer i1 = 12;
  parameter Integer i2 = 8;
end OtherModel;

function f
  input Integer inInt;
  output Integer outInt;
algorithm
  outInt := inInt + 1138;
end f;

model Operators
  constant Integer unusedArray1[3] = {1,2,3};
  constant Integer unusedArray2[1, 3] = [2,3,4];
  constant Integer unusedMatrix[2, 2] = [3,4;5,6];
  constant Integer unusedArray3[7,1] = [1:2:14];
  constant Boolean b = true;
  constant String s = "te" + "st";
  Integer iarr[2];
  OtherModel om;
  Integer i1;
  Integer i2;
  Integer i3;
equation
  iarr[1] = 2;
  iarr[2] = 3;
  om.i1 = iarr[1];
  om.i2 = iarr[2];
  i1 = 4711;
  i2 = f(i1);
  i3 = if b then 36 else 37;
end Operators;

// Result:
// function f
//   input Integer inInt;
//   output Integer outInt;
// algorithm
//   outInt := 1138 + inInt;
// end f;
//
// class Operators
//   constant Integer unusedArray1[1] = 1;
//   constant Integer unusedArray1[2] = 2;
//   constant Integer unusedArray1[3] = 3;
//   constant Integer unusedArray2[1,1] = 2;
//   constant Integer unusedArray2[1,2] = 3;
//   constant Integer unusedArray2[1,3] = 4;
//   constant Integer unusedMatrix[1,1] = 3;
//   constant Integer unusedMatrix[1,2] = 4;
//   constant Integer unusedMatrix[2,1] = 5;
//   constant Integer unusedMatrix[2,2] = 6;
//   constant Integer unusedArray3[1,1] = 1;
//   constant Integer unusedArray3[2,1] = 3;
//   constant Integer unusedArray3[3,1] = 5;
//   constant Integer unusedArray3[4,1] = 7;
//   constant Integer unusedArray3[5,1] = 9;
//   constant Integer unusedArray3[6,1] = 11;
//   constant Integer unusedArray3[7,1] = 13;
//   constant Boolean b = true;
//   constant String s = "test";
//   Integer iarr[1];
//   Integer iarr[2];
//   parameter Integer om.i1 = 12;
//   parameter Integer om.i2 = 8;
//   Integer i1;
//   Integer i2;
//   Integer i3;
// equation
//   iarr[1] = 2;
//   iarr[2] = 3;
//   om.i1 = iarr[1];
//   om.i2 = iarr[2];
//   i1 = 4711;
//   i2 = f(i1);
//   i3 = 36;
// end Operators;
// endResult
