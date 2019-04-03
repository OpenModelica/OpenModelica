// name: BindingArray3
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  Real x = 1.0;
end A;

model B
  A a[3];
end B;

model BindingArray3
  B b[2](each a(x = {2, 3, 4}));
end BindingArray3;

// Result:
// class BindingArray3
//   Real b[1].a[1].x = 2.0;
//   Real b[1].a[2].x = 3.0;
//   Real b[1].a[3].x = 4.0;
//   Real b[2].a[1].x = 2.0;
//   Real b[2].a[2].x = 3.0;
//   Real b[2].a[3].x = 4.0;
// end BindingArray3;
// endResult
