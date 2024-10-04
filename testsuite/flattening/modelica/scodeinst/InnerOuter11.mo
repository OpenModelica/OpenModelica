// name: InnerOuter11
// keywords:
// status: correct
//

partial function A
  input Real x;
  output Real y;
end A;

partial model M1
  outer function f = A;
end M1;

model M2
  extends M1;
  Real x = f(time);
end M2;

partial model M3
  M2 m2;
end M3;

partial model M4
  extends M3;
end M4;

model M5
  extends M4;
end M5;

model InnerOuter11
  function B
    input Real x;
    output Real y = x;
  end B;
  inner function f = B;
  M5 m;
end InnerOuter11;

// Result:
// function InnerOuter11.f
//   input Real x;
//   output Real y = x;
// end InnerOuter11.f;
//
// class InnerOuter11
//   Real m.m2.x = InnerOuter11.f(time);
// end InnerOuter11;
// endResult
