// name: redeclare6.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//


model A
  replaceable Integer x;
end A;

model B
  extends A(redeclare replaceable Integer x = 2);
end B;

model C
  extends B(redeclare Real x = 3);
end C;

// Result:
// class C
//   Real x = 3.0;
// end C;
// endResult
