// name: cond4.mo
// keywords:
// status: correct
//

model A
  parameter Boolean b;
  Real x if b;
end A;

model B
  parameter Boolean b = true;
  A a(b = b);
end B;

// Result:
// class B
//   final parameter Boolean b = true;
//   final parameter Boolean a.b = true;
//   Real a.x;
// end B;
// endResult
