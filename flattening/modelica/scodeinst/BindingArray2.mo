// name: BindingArray2
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  Real x = 1.0;
end A;

model BindingArray2
  A a[3](each x = 2.0);
end BindingArray2;

// Result:
// class BindingArray2
//   Real a[1].x = 2.0;
//   Real a[2].x = 2.0;
//   Real a[3].x = 2.0;
// end BindingArray2;
// endResult
