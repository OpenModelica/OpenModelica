// name: ConstrainingClassFunc2
// keywords:
// status: correct
// cflags: -d=newInst
//

function f
  input Real x;
  output Real y;
end f;

model A
  replaceable function f2 = f(x = 0);

  Real x = f2();
end A;

model ConstrainingClassFunc2
  A a(redeclare function f2 = f(x = 1));
end ConstrainingClassFunc2;

// Result:
// function ConstrainingClassFunc2.a.f2
//   input Real x = 1.0;
//   output Real y;
// end ConstrainingClassFunc2.a.f2;
//
// class ConstrainingClassFunc2
//   Real a.x = ConstrainingClassFunc2.a.f2(1.0);
// end ConstrainingClassFunc2;
// endResult
