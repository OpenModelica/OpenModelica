// name:     Modification6
// keywords: modification
// status:   correct
//
// This file tests modification precedence.
//

model M
  replaceable model Foo
    parameter Real q = 1.0;
  end Foo;
  Foo f(q=2.0);
end M;

model Modification6
  model myFoo parameter Real q=5;end myFoo;
  M m1(redeclare model Foo=myFoo(q=3.0), f(q=4.0));
  M m2(f(q=4.0), redeclare model Foo=myFoo(q=3.0));
end Modification6;


// Result:
// class Modification6
//   parameter Real m1.f.q = 4.0;
//   parameter Real m2.f.q = 4.0;
// end Modification6;
// endResult
