// name: IfExpression16
// keywords:
// status: correct
// cflags: -d=newInst
//

record R
  parameter Real x[:];
end R;

record IfExpression16
  parameter R r[2](x = if true then {{0}, {0}} else {{0}});
end IfExpression16;

// Result:
// class IfExpression16
//   parameter Real r[1].x[1] = 0.0;
//   parameter Real r[2].x[1] = 0.0;
// end IfExpression16;
// endResult
