// name: IfExpression13
// keywords:
// status: correct
// cflags: -d=newInst
//

record R
  constant Boolean cond = false;
  constant Real[3] a = if cond then {1.0} else {1.0, 2.0, 3.0};
  constant Real[2] b = a[1:end-1];
end R;

model IfExpression13
  R r = R();
end IfExpression13;

// Result:
// class IfExpression13
//   constant Boolean r.cond = false;
//   constant Real r.a[1] = 1.0;
//   constant Real r.a[2] = 2.0;
//   constant Real r.a[3] = 3.0;
//   constant Real r.b[1] = 1.0;
//   constant Real r.b[2] = 2.0;
// end IfExpression13;
// endResult
