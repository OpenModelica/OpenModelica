// name: RecordExtends1
// keywords:
// status: correct
// cflags: -d=newInst
//

record R
  Real x;
end R;

model M1
  record R1 = R(x = 1.0);
  R1 r1;
end M1;

model M2
  record R2 = R(x = 2.0);
  R2 r2;
end M2;

model RecordExtends1
  M1 m1;
  M2 m2;
end RecordExtends1;

// Result:
// class RecordExtends1
//   Real m1.r1.x = 1.0;
//   Real m2.r2.x = 2.0;
// end RecordExtends1;
// endResult
