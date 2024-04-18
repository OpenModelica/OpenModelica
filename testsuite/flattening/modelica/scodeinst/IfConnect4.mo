// name: IfConnect4
// keywords:
// status: correct
// cflags: -d=newInst
//
//

connector C
  Real e;
  flow Real f;
end C;

model IfConnect4
  parameter Boolean b(start = true);
  C c1, c2;
equation
  if b then
    connect(c1, c2);
  end if;
end IfConnect4;

// Result:
// class IfConnect4
//   final parameter Boolean b(start = true);
//   Real c1.e;
//   Real c1.f;
//   Real c2.e;
//   Real c2.f;
// equation
//   c1.e = c2.e;
//   -(c1.f + c2.f) = 0.0;
//   c1.f = 0.0;
//   c2.f = 0.0;
// end IfConnect4;
// [flattening/modelica/scodeinst/IfConnect4.mo:14:3-14:36:writable] Warning: Parameter b has no value, and is fixed during initialization (fixed=true), using available start value (start=true) as default value.
//
// endResult
