// name: FuncViaComp
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

model FuncViaComp
  A a;
  Real x = a.f(1);
end FuncViaComp;

// Result:
// class FuncViaComp
//   Real x = 2.0;
// end FuncViaComp;
// endResult
