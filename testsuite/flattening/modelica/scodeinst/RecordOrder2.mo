// name: RecordOrder2
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

model RecordOrder2
  R1 r1;
  R2 r2 = r1;
equation
  r1 = r2;
end RecordOrder2;

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
// class RecordOrder2
//   Real r1.x;
//   Real r1.y;
//   Real r2.y = r1.y;
//   Real r2.x = r1.x;
// equation
//   r1 = R1(r2.x, r2.y);
// end RecordOrder2;
// endResult
