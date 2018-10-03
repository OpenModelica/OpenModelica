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
// class B
//   constant Real a1.z = 2.0;
//   constant Real a1.w = 4.0;
//   constant Real a2.z = 3.0;
//   constant Real a2.w = 9.0;
//   Real x = 4.0;
//   Real y = 9.0;
// end B;
// endResult
