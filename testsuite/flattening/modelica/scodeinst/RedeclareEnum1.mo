// name: RedeclareEnum1
// keywords:
// status: correct
//

model A
  replaceable type E = enumeration(:);
  E e;
end A;

model RedeclareEnum1
  extends A(redeclare type E = enumeration(a, b, c));
end RedeclareEnum1;


// Result:
// class RedeclareEnum1
//   enumeration(a, b, c) e;
// end RedeclareEnum1;
// endResult
