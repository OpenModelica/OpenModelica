// name: IfConnect2
// keywords:
// status: correct
// cflags: -d=newInst
//
//

connector C
  Real e;
  flow Real f;
end C;

model IfConnect2
  parameter Boolean b = false;
  C c1, c2;
equation
  if b then
    connect(c1, c2);
  end if;
end IfConnect2;

// Result:
// class IfConnect2
//   parameter Boolean b = false;
//   Real c1.e;
//   Real c1.f;
//   Real c2.e;
//   Real c2.f;
// equation
//   c1.f = 0.0;
//   c2.f = 0.0;
// end IfConnect2;
// endResult
