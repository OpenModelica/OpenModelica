// name: RecordBinding8
// keywords:
// status: correct
//

record R1
  Real x = 1.0;
end R1;

record R2
  R1 r1;
end R2;

function f
  input R2 r2;
  output Real x = r2.r1.x;
end f;

model RecordBinding8
  Real x;
equation
  x = f();
end RecordBinding8;

// Result:
// class RecordBinding8
//   Real x;
// equation
//   x = 1.0;
// end RecordBinding8;
// endResult
