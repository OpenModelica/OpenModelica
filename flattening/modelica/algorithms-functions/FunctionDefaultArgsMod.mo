// name:     FunctionDefaultArgsMod
// keywords: functions, default arguments, modifier, #2729
// status:   correct
//
// Checks that it's possible to add default argument to a derived function via a
// modifier.
//

function f
  input Real x;
  input Real r;
  output Real o = x+r;
end f;

model FunctionDefaultArgsMod
  Real p = 2.0;
  function g = f(r=p);
  Real x = g(1.0);
end FunctionDefaultArgsMod;

// Result:
// function FunctionDefaultArgsMod.g
//   input Real x;
//   input Real r = p;
//   output Real o = x + r;
// end FunctionDefaultArgsMod.g;
//
// class FunctionDefaultArgsMod
//   Real p = 2.0;
//   Real x = FunctionDefaultArgsMod.g(1.0, p);
// end FunctionDefaultArgsMod;
// endResult
