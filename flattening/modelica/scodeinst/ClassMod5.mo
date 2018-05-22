// name: ClassMod5
// status: correct
// cflags: -d=newInst

model A
  type T = Real[3];
  T t;
end A;

model A2
  type T = Real[3];
  T t[2];
end A2;

model B
  A a;
  A2 a2;
end B;

model ClassMod5
  B b[3](a(T(start = {{1, 2, 3}, {4, 5, 6}, {7, 8, 9}})));
  B b2(a2(each T(start = {1, 2, 3})));
end ClassMod5;

// Result:
// class ClassMod5
//   Real b[1].a.t[1](start = 1.0);
//   Real b[1].a.t[2](start = 2.0);
//   Real b[1].a.t[3](start = 3.0);
//   Real b[1].a2.t[1,1];
//   Real b[1].a2.t[1,2];
//   Real b[1].a2.t[1,3];
//   Real b[1].a2.t[2,1];
//   Real b[1].a2.t[2,2];
//   Real b[1].a2.t[2,3];
//   Real b[2].a.t[1](start = 4.0);
//   Real b[2].a.t[2](start = 5.0);
//   Real b[2].a.t[3](start = 6.0);
//   Real b[2].a2.t[1,1];
//   Real b[2].a2.t[1,2];
//   Real b[2].a2.t[1,3];
//   Real b[2].a2.t[2,1];
//   Real b[2].a2.t[2,2];
//   Real b[2].a2.t[2,3];
//   Real b[3].a.t[1](start = 7.0);
//   Real b[3].a.t[2](start = 8.0);
//   Real b[3].a.t[3](start = 9.0);
//   Real b[3].a2.t[1,1];
//   Real b[3].a2.t[1,2];
//   Real b[3].a2.t[1,3];
//   Real b[3].a2.t[2,1];
//   Real b[3].a2.t[2,2];
//   Real b[3].a2.t[2,3];
//   Real b2.a.t[1];
//   Real b2.a.t[2];
//   Real b2.a.t[3];
//   Real b2.a2.t[1,1](start = 1.0);
//   Real b2.a2.t[1,2](start = 2.0);
//   Real b2.a2.t[1,3](start = 3.0);
//   Real b2.a2.t[2,1](start = 1.0);
//   Real b2.a2.t[2,2](start = 2.0);
//   Real b2.a2.t[2,3](start = 3.0);
// end ClassMod5;
// endResult
