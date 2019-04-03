// name: ClassMod6
// status: correct
// cflags: -d=newInst

model X
  Real x;
end X;

model A
  model T = X[3];
  T t;
end A;

model A2
  model T = X[3];
  T t[2];
end A2;

model B
  A a;
  A2 a2;
end B;

model ClassMod6
  B b[3](a(T(x = {{1, 2, 3}, {4, 5, 6}, {7, 8, 9}})));
  B b2(a2(each T(x = {1, 2, 3})));
end ClassMod6;

// Result:
// class ClassMod6
//   Real b[1].a.t[1].x = 1.0;
//   Real b[1].a.t[2].x = 2.0;
//   Real b[1].a.t[3].x = 3.0;
//   Real b[1].a2.t[1,1].x;
//   Real b[1].a2.t[1,2].x;
//   Real b[1].a2.t[1,3].x;
//   Real b[1].a2.t[2,1].x;
//   Real b[1].a2.t[2,2].x;
//   Real b[1].a2.t[2,3].x;
//   Real b[2].a.t[1].x = 4.0;
//   Real b[2].a.t[2].x = 5.0;
//   Real b[2].a.t[3].x = 6.0;
//   Real b[2].a2.t[1,1].x;
//   Real b[2].a2.t[1,2].x;
//   Real b[2].a2.t[1,3].x;
//   Real b[2].a2.t[2,1].x;
//   Real b[2].a2.t[2,2].x;
//   Real b[2].a2.t[2,3].x;
//   Real b[3].a.t[1].x = 7.0;
//   Real b[3].a.t[2].x = 8.0;
//   Real b[3].a.t[3].x = 9.0;
//   Real b[3].a2.t[1,1].x;
//   Real b[3].a2.t[1,2].x;
//   Real b[3].a2.t[1,3].x;
//   Real b[3].a2.t[2,1].x;
//   Real b[3].a2.t[2,2].x;
//   Real b[3].a2.t[2,3].x;
//   Real b2.a.t[1].x;
//   Real b2.a.t[2].x;
//   Real b2.a.t[3].x;
//   Real b2.a2.t[1,1].x = 1.0;
//   Real b2.a2.t[1,2].x = 2.0;
//   Real b2.a2.t[1,3].x = 3.0;
//   Real b2.a2.t[2,1].x = 1.0;
//   Real b2.a2.t[2,2].x = 2.0;
//   Real b2.a2.t[2,3].x = 3.0;
// end ClassMod6;
// endResult
