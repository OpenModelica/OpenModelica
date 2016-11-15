// name: func1.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//


model A
  constant Real z;

  function f
    input Real x;
    output Real y;
  algorithm
    y := x * z;
  end f;

  constant Real w = f(z);
end A;

model B
  A a1(z = 2.0);
  A a2(z = 3.0);
  Real x = a1.w;
  Real y = a2.w;
end B;

// Result:
// function a1.f
//   input Real x;
//   output Real y;
// algorithm
//   y := 2.0 * x;
// end a1.f;
//
// function a2.f
//   input Real x;
//   output Real y;
// algorithm
//   y := 3.0 * x;
// end a2.f;
//
// class B
//   Real x = a1.f(2.0);
//   Real y = a2.f(3.0);
// end B;
// endResult
