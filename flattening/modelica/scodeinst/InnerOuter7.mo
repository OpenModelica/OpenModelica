// name: InnerOuter7
// keywords: 
// status: correct
// cflags: -d=newInst
//

model A
  outer Real x;
  Real y = x; 
end A;

model B
  A a;
  Real z;
equation
  z = a.x;
end B;

model C
  inner Real x;
  B b;
end C;

model InnerOuter7
  C c;
end InnerOuter7;

// Result:
// class InnerOuter7
//   Real c.x;
//   Real c.b.a.y = c.x;
//   Real c.b.z;
// equation
//   c.b.z = c.x;
// end InnerOuter7;
// endResult
