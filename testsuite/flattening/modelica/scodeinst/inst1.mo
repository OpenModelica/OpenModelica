// name: inst1.mo
// keywords:
// status: incorrect
//


model A
  replaceable Real x;
end A;

model B
  extends A(redeclare Integer x);
end B;

// Result:
// class B
//   Integer x;
// end B;
// endResult
