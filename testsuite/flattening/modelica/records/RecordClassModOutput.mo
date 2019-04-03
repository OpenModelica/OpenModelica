// name: RecordClassModOutput.mo
// keywords: record, submod
// status: correct
//
// Checks that output records from functions with classmod modification get bindings
//

record R1
  Integer i1 = 10;
  Integer r1 = 10;
end R1;

function out1
  output R1 m(i1=2,r1=2);
end out1;

function out2
  output R1 m(i1=2,r1=2);
protected
  R1 mintern(i1 = 1, r1 = 1);
algorithm
  m := mintern;
end out2;

model test
   R1 m2 = R1(i1 = 9, r1 = 9);
   R1 m3 = m2;
   R1 m4 = out1();
   R1 m5 = out2();
end test;


// Result:
// function R1 "Automatically generated record constructor for R1"
//   input Integer i1 = 10;
//   input Integer r1 = 10;
//   output R1 res;
// end R1;
//
// function out1
//   output R1 m = R1(2, 2);
// end out1;
//
// function out2
//   output R1 m = R1(2, 2);
//   protected R1 mintern = R1(1, 1);
// algorithm
//   m := mintern;
// end out2;
//
// class test
//   Integer m2.i1 = 9;
//   Integer m2.r1 = 9;
//   Integer m3.i1 = m2.i1;
//   Integer m3.r1 = m2.r1;
//   Integer m4.i1 = 2;
//   Integer m4.r1 = 2;
//   Integer m5.i1 = 1;
//   Integer m5.r1 = 1;
// end test;
// endResult
