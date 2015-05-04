// name:     Matrix1
// keywords: array,matrices
// status:   correct
//
// This is a simple test of basic matrix handling.
//

model test
  parameter Real K[2,2]=(Em)*{{1,-1},{-1,1}};
  parameter Real X[2]=Em*{1,2};
  parameter Real Em=1;
  parameter Real A=0.1;
  parameter Real L=4;
end test;
// Result:
// class test
//   parameter Real K[1,1] = Em;
//   parameter Real K[1,2] = -Em;
//   parameter Real K[2,1] = -Em;
//   parameter Real K[2,2] = Em;
//   parameter Real X[1] = Em;
//   parameter Real X[2] = 2.0 * Em;
//   parameter Real Em = 1.0;
//   parameter Real A = 0.1;
//   parameter Real L = 4.0;
// end test;
// endResult
