// name: RedeclareEnum5
// keywords:
// status: correct
//

model A
  replaceable type E = enumeration(:);
  E e;
end A;

model RedeclareEnum5
  extends A(redeclare type E = E3);
  type E2 = enumeration(a, b, c);
  type E3 = E2;
end RedeclareEnum5;


// Result:
// class RedeclareEnum5
//   enumeration(a, b, c) e;
// end RedeclareEnum5;
// endResult
