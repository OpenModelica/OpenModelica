// name: PropagateExtends.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//

model A
  Real x;
  Real y;
end A;

model B
  extends A;
end B;

model C
  extends B;
end C;

model D
  extends C(x(unit="kg"));
end D;

model E
  extends D(x(start = 1), y(start=1));
end E;

model F
 E e;
 D d;
end F;

// Result:
// class F
//   Real e.x(unit = "kg", start = 1);
//   Real e.y(start = 1);
//   Real d.x(unit = "kg");
//   Real d.y;
// end F;
// endResult
