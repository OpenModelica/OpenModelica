// name:     InnerClass1
// keywords: dynamic scoping
// status:   correct
//
// This example demonstrates how dynamic
// scoping can be used both for models and for functions.
//

partial function foo
  input Real x;
  output Real y;
end foo;

partial model bar
  parameter Real p;
end bar;

model A
  outer function myfoo=foo;
  Real x;
equation
  x=myfoo(time);
end A;

model B
  outer model mybar=bar;
  mybar x(p=2);
  A a;
end B;

model InnerClass1
  inner function myfoo
    extends foo;
  algorithm
    y:=sin(x);
  end myfoo;
  inner model mybar
    extends bar;
    Real x;
  equation
    der(x)=p;
  end mybar;
  B b;
  A a;
end InnerClass1;

// Result:
// class InnerClass1
// parameter Real b.x.p = 2;
// Real b.a.x;
// Real a.x;
// equation
//   b.a.x = A.myfoo(time);
//   a.x = A.myfoo(time);
// end InnerClass1;
// endResult
