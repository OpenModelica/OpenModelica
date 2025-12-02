// name: dim13
// keywords:
// status: correct
//


model A
  parameter Integer n = 3;
end A;

model B
  extends A;
  parameter Real x[n] = ones(n);
end B;

// Result:
// class B
//   final parameter Integer n = 3;
//   parameter Real x[1] = 1.0;
//   parameter Real x[2] = 1.0;
//   parameter Real x[3] = 1.0;
// end B;
// endResult
