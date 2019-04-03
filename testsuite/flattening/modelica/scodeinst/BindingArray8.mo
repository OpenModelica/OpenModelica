// name: BindingArray8
// keywords:
// status: correct
// cflags: -d=newInst
//

model BindingArray8  
  parameter Real x[4] = {1, 2, 3, 4};
  parameter Real y[2, 4] = {x, {5, 6, 7, 8}};
end BindingArray8;

// Result:
// class BindingArray8
//   parameter Real x[1] = 1.0;
//   parameter Real x[2] = 2.0;
//   parameter Real x[3] = 3.0;
//   parameter Real x[4] = 4.0;
//   parameter Real y[1,1] = x[1];
//   parameter Real y[1,2] = x[2];
//   parameter Real y[1,3] = x[3];
//   parameter Real y[1,4] = x[4];
//   parameter Real y[2,1] = 5.0;
//   parameter Real y[2,2] = 6.0;
//   parameter Real y[2,3] = 7.0;
//   parameter Real y[2,4] = 8.0;
// end BindingArray8;
// endResult
