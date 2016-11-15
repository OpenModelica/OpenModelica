// name: func9.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//

model M
  Real x, y;
  constant Integer n = 2;

  function f
    input Real x;
    output Real y;
  algorithm
    y := x * 2;
  end f;
equation
  x = f(n);
end M;

model N
  M m;
end N;

// Result:
// function m.f
//   input Real x;
//   output Real y;
// algorithm
//   y := 2.0 * x;
// end m.f;
//
// class N
//   Real m.x;
//   Real m.y;
// equation
//   m.x = m.f(2.0);
// end N;
// endResult
