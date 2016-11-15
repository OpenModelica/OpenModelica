// name: PropagateRedeclareMod1
// keywords:
// status: correct
// cflags:   -d=newInst
//

model A
  replaceable Real x;
  replaceable Real y;
  replaceable Real z;
end A;

model B
  replaceable A a(x = 4);
end B;

model C
  extends B(replaceable A a(y = 5));
end C;

model D
  extends C(replaceable A a(z = 6));
end D;

// Result:
// class D
//   Real a.x = 4.0;
//   Real a.y = 5.0;
//   Real a.z = 6.0;
// end D;
// endResult
