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
// function a2.f
//   input Real x;
//   output Real y;
// algorithm
//   y := x * A.z;
// end a2.f;
//
// class B
//   constant Real a1.z = 2.0;
//   constant Real a1.w = a1.f(a1.z);
//   constant Real a2.z = 3.0;
//   constant Real a2.w = a2.f(a2.z);
//   Real x = a1.w;
//   Real y = a2.w;
// end B;
// endResult
