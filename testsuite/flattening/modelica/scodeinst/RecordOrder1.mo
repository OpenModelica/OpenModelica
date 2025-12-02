// name: RecordOrder1
// keywords:
// status: correct
//

record R1
  Real x;
  Real y;
end R1;

record R2
  Real y;
  Real x;
end R2;

model RecordOrder1
  R1 r1;
equation
  r1 = R2(1.0, 2.0);
end RecordOrder1;

// Result:
// function R1 "Automatically generated record constructor for R1"
//   input Real x;
//   input Real y;
//   output R1 res;
// end R1;
//
// function R2 "Automatically generated record constructor for R2"
//   input Real y;
//   input Real x;
//   output R2 res;
// end R2;
//
// class RecordOrder1
//   Real r1.x;
//   Real r1.y;
// equation
//   r1 = R1(2.0, 1.0);
// end RecordOrder1;
// endResult
