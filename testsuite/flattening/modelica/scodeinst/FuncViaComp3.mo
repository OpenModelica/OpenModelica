// name: FuncViaComp3
// keywords:
// status: correct
// cflags: -d=newInst
//
// Checks that functions can be called via components.
//


model A
  function f
    input Integer n;
    output Real x = 2;
  end f;
end A;

model B
  A a;
end B;

model FuncViaComp3
  B b;
  Real x = b.a.f(1);
end FuncViaComp3;

// Result:
// class FuncViaComp3
//   Real x = 2.0;
// end FuncViaComp3;
// endResult
