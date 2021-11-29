// name: ArrayConstructorRecord2
// keywords:
// status: correct
// cflags: -d=newInst
//

record R
  Real x = 1;
end R;

model ArrayConstructorRecord2
  parameter R r[3];
  Real x[:] = {i.x for i in r};
end ArrayConstructorRecord2;

// Result:
// class ArrayConstructorRecord2
//   parameter Real r[1].x = 1.0;
//   parameter Real r[2].x = 1.0;
//   parameter Real r[3].x = 1.0;
//   Real x[1];
//   Real x[2];
//   Real x[3];
// equation
//   x = {1.0, 1.0, 1.0};
// end ArrayConstructorRecord2;
// endResult
