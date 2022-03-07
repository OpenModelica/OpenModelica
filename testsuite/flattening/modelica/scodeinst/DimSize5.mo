// name: DimSize5
// keywords:
// status: correct
// cflags: -d=newInst
//

record A
  parameter B b;
end A;

record B
  parameter Integer n;
  parameter Real[:] x;
end B;

model DimCyclic5
  parameter A a(b = B(n = 3, x = x));
  parameter Integer n = a.b.n;
  final parameter Real[n] x = {i for i in 1:n};
end DimCyclic5;

// Result:
// class DimCyclic5
//   final parameter Integer a.b.n = 3;
//   parameter Real a.b.x[1] = x[1];
//   parameter Real a.b.x[2] = x[2];
//   parameter Real a.b.x[3] = x[3];
//   final parameter Integer n = 3;
//   final parameter Real x[1] = 1.0;
//   final parameter Real x[2] = 2.0;
//   final parameter Real x[3] = 3.0;
// end DimCyclic5;
// endResult
