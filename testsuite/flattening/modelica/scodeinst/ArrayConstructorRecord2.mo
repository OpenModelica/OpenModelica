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
  parameter Real x[:] = {i.x for i in r};
end ArrayConstructorRecord2;

// Result:
// function R "Automatically generated record constructor for R"
//   input Real x = 1.0;
//   output R res;
// end R;
//
// class ArrayConstructorRecord2
//   parameter Real r[1].x = 1.0;
//   parameter Real r[2].x = 1.0;
//   parameter Real r[3].x = 1.0;
//   parameter Real x[1] = 1.0;
//   parameter Real x[2] = 1.0;
//   parameter Real x[3] = 1.0;
// end ArrayConstructorRecord2;
// endResult
