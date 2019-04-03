// name: BindingArray1
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  Real x = 1.0;
end A;

model BindingArray1
  A a[3](x = {1, 2, 3});
end BindingArray1;

// Result:
// class BindingArray1
//   Real a[1].x = 1.0;
//   Real a[2].x = 2.0;
//   Real a[3].x = 3.0;
// end BindingArray1;
// endResult
