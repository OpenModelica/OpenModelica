// name: IfConnect1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

connector C
  Real e;
  flow Real f;
end C;

model IfConnect1
  parameter Boolean b = true;
  C c1, c2;
equation
  if b then
    connect(c1, c2);
  end if;
end IfConnect1;

// Result:
// class IfConnect1
//   parameter Boolean b = true;
//   Real c1.e;
//   Real c1.f;
//   Real c2.e;
//   Real c2.f;
// equation
//   c1.e = c2.e;
//   (-c1.f) + (-c2.f) = 0.0;
//   c1.f = 0.0;
//   c2.f = 0.0;
// end IfConnect1;
// endResult
