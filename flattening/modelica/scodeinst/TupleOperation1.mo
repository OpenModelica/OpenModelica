// name: TupleOperation1
// keywords:
// status: correct
// cflags: -d=newInst
//

function f
  input Real t;
  output Real x = 1.0;
  output Real y = 2.0;
end f;

model TupleOperation1
  Real x = -f(time);
end TupleOperation1;

// Result:
// function f
//   input Real t;
//   output Real x = 1.0;
//   output Real y = 2.0;
// end f;
//
// class TupleOperation1
//   Real x = -f(time)[1];
// end TupleOperation1;
// endResult
