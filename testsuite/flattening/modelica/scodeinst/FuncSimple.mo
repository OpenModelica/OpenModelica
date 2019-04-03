// name: FuncSimple
// keywords:
// status: correct
// cflags: -d=newInst
//
// A very simple function test.
//

function f
  input Real x;
  output Real y = x;
end f;

model FuncSimple
  Real x = f(1.0);
end FuncSimple;

// Result:
// class FuncSimple
//   Real x = 1.0;
// end FuncSimple;
// endResult
