// name: RecordConstructor3
// keywords:
// status: correct
// cflags: -d=newInst
//
//

record R
  parameter Real[:, 3] A;
  parameter Real x = max(A[:, 1]);
end R;

model RecordConstructor3
  parameter R r = R(A = [0, 1, 2]);
end RecordConstructor3;

// Result:
// class RecordConstructor3
//   parameter Real r.A[1,1] = 0.0;
//   parameter Real r.A[1,2] = 1.0;
//   parameter Real r.A[1,3] = 2.0;
//   parameter Real r.x = 0.0;
// end RecordConstructor3;
// endResult
