// name: TupleOperation2
// keywords:
// status: correct
// cflags: -d=newInst
//

function f
  input Real t;
  output Real x = 1.0;
  output Real y = 2.0;
end f;

function f2
  input Real t;
  output Real x = 3.0;
  output Real y = 4.0;
  output Real z = 5.0;
end f2;

model TupleOperation2
  Real x = f(time) + f2(time);
end TupleOperation2;

// Result:
// function f
//   input Real t;
//   output Real x = 1.0;
//   output Real y = 2.0;
// end f;
//
// function f2
//   input Real t;
//   output Real x = 3.0;
//   output Real y = 4.0;
//   output Real z = 5.0;
// end f2;
//
// class TupleOperation2
//   Real x = f(time)[1] + f2(time)[1];
// end TupleOperation2;
// endResult
