// name: mod12.mo
// keywords:
// status: correct
//

model A
  Real x;
end A;

model B
  extends A;
  Real x;
end B;

model C
  extends B(x = 5);
end C;

// Result:
// class C
//   Real x = 5.0;
// end C;
// endResult
