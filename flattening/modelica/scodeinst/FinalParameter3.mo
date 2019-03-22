// name: FinalParameter3
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  parameter Real x;
end A;

model FinalParameter3
  final A a(x = 3.0);
  Real y = a.x;
end FinalParameter3;

// Result:
// class FinalParameter3
//   final parameter Real a.x = 3.0;
//   Real y = 3.0;
// end FinalParameter3;
// endResult
