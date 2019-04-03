// name: FinalParameter2
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  parameter Real x;
end A;

model FinalParameter2
  A a(final x = 3.0);
  Real y = a.x;
end FinalParameter2;

// Result:
// class FinalParameter2
//   final parameter Real a.x = 3.0;
//   Real y = 3.0;
// end FinalParameter2;
// endResult
