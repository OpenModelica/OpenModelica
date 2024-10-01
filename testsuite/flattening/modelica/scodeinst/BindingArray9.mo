// name: BindingArray9
// keywords:
// status: correct
//

model A
  parameter Real[:] b;
end A;

model BindingArray9
  A a[5](b = fill({1}, 5));
end BindingArray9;

// Result:
// class BindingArray9
//   parameter Real a[1].b[1] = 1.0;
//   parameter Real a[2].b[1] = 1.0;
//   parameter Real a[3].b[1] = 1.0;
//   parameter Real a[4].b[1] = 1.0;
//   parameter Real a[5].b[1] = 1.0;
// end BindingArray9;
// endResult
