// name: redeclare5.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//


model A
  Real x;
end A;

model B
  extends A;
  Real y;
end B;

model C
  replaceable B b extends A(x = 4, y = 6) "hej";
end C;

// Result:
// class C
//   Real b.x = 4.0;
//   Real b.y = 6.0;
// end C;
// endResult
