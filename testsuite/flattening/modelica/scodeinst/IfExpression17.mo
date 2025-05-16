// name: IfExpression17
// keywords:
// status: correct
//

model M
  Real u;
  Real x;
  parameter Boolean dynamic = true;
equation
  u = sin(10*time);
  (if dynamic then der(x) else 0) + x = u;
end M;

model S1
  M m;
end S1;

model IfExpression17
  M m(dynamic = false);
end IfExpression17;

// Result:
// class IfExpression17
//   Real m.u;
//   Real m.x;
//   final parameter Boolean m.dynamic = false;
// equation
//   m.u = sin(10.0 * time);
//   m.x = m.u;
// end IfExpression17;
// endResult
