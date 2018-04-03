// name: const8.mo
// keywords:
// status: correct
// cflags: -d=newInst
//


model M
  parameter Real A[i, j];
  parameter Integer i = size(A, 2);
  parameter Integer j = size(A, 1);
end M;

model M2
  parameter Real A[2, 3];
  parameter Integer j = size(A, i);
  parameter Integer i = size(A, 1);
end M2;

// Result:
// class M2
//   parameter Real A[1,1];
//   parameter Real A[1,2];
//   parameter Real A[1,3];
//   parameter Real A[2,1];
//   parameter Real A[2,2];
//   parameter Real A[2,3];
//   parameter Integer j = size(A, i);
//   parameter Integer i = 2;
// end M2;
// endResult
