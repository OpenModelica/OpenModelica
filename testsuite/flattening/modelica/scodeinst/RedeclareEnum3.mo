// name: RedeclareEnum3
// keywords:
// status: correct
//

model A
  replaceable type E = enumeration(a, b, c);
  E e;
end A;

model RedeclareEnum3
  extends A(redeclare type E = enumeration(a, b, c));
end RedeclareEnum3;


// Result:
// class RedeclareEnum3
//   enumeration(a, b, c) e;
// end RedeclareEnum3;
// endResult
