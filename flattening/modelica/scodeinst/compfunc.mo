// name: compfunc.mo
// keywords:
// status: correct
// cflags:   -d=newInst
// teardown_command: rm -rf B_a____f*
//


model A
  function f
    input Integer n;
    output Real x = 2;
  end f;
end A;

model B
  A a;
  Real x = a.f(1);
end B;

// Result:
// function a.f
//   input Integer n;
//   output Real x;
// algorithm
//   x := 2.0;
// end a.f;
//
// class B
//   Real x = a.f(1);
// end B;
// endResult
