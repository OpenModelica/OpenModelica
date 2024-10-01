// name: ArrayConstructorRecord1
// keywords:
// status: correct
//

record R
  Real x;
end R;

model ArrayConstructorRecord1
  parameter R r[3](x = {1, 2, 3});
  parameter Real x[:] = {i.x for i in r};
end ArrayConstructorRecord1;

// Result:
// function R "Automatically generated record constructor for R"
//   input Real x;
//   output R res;
// end R;
//
// class ArrayConstructorRecord1
//   parameter Real r[1].x = 1.0;
//   parameter Real r[2].x = 2.0;
//   parameter Real r[3].x = 3.0;
//   parameter Real x[1] = 1.0;
//   parameter Real x[2] = 2.0;
//   parameter Real x[3] = 3.0;
// end ArrayConstructorRecord1;
// endResult
