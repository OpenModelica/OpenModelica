// name: loop3.mo
// keywords:
// status: correct
//


model A
  parameter Integer n = 2;
  parameter Real x[2, 3] = zeros(2, 3);
  parameter Integer i = size(x, n);
end A;

// Result:
// class A
//   parameter Integer n = 2;
//   parameter Real x[1,1] = 0.0;
//   parameter Real x[1,2] = 0.0;
//   parameter Real x[1,3] = 0.0;
//   parameter Real x[2,1] = 0.0;
//   parameter Real x[2,2] = 0.0;
//   parameter Real x[2,3] = 0.0;
//   parameter Integer i = size(x, n);
// end A;
// endResult
