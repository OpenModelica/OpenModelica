// name:     RedeclareFunction1
// keywords: redeclare function bug1432
// status:   correct
//
// Checks that it's possible to redeclare a function in several steps.
//
//

partial function part_func
  input Real x;
  output Real y;
end part_func;

function func1
  extends part_func;
algorithm
  y := x;
end func1;

function func2
  extends part_func;
algorithm
  y := 2 * x;
end func2;

model model1
  replaceable function func = part_func;
  Real x;
  Real y;
equation
  x = func(y);
end model1;

model model2 = model1(replaceable function func = func1);
model model3 = model2(replaceable function func = func2);

model RedeclareFunction1
  model2 m2;
  model3 m3;
end RedeclareFunction1;

// Result:
// function model2.func
//   input Real x;
//   output Real y;
// algorithm
//   y := x;
// end model2.func;
//
// function model3.func
//   input Real x;
//   output Real y;
// algorithm
//   y := 2.0 * x;
// end model3.func;
//
// class RedeclareFunction1
//   Real m2.x;
//   Real m2.y;
//   Real m3.x;
//   Real m3.y;
// equation
//   m2.x = model2.func(m2.y);
//   m3.x = model3.func(m3.y);
// end RedeclareFunction1;
// endResult
