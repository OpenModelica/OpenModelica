// name: BindingArray4
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

model BindingArray4
  B b[2](each a.x = 2);
end BindingArray4;

// Result:
// class BindingArray4
//   Real b[1].a[1].x = 2.0;
//   Real b[1].a[2].x = 2.0;
//   Real b[1].a[3].x = 2.0;
//   Real b[2].a[1].x = 2.0;
//   Real b[2].a[2].x = 2.0;
//   Real b[2].a[3].x = 2.0;
// end BindingArray4;
// endResult
