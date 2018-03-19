// name: Final2
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  parameter Real x;
end A;

model Final2
  final A a(x = 1.0);
end Final2;

// Result:
// class Final2
//   final parameter Real a.x = 1.0;
// end Final2;
// endResult
