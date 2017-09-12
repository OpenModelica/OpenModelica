// name: Range1.mo
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model Range1
  type E = enumeration(one, two, three);
  E x[E] = E.one:E.three;
end Range1;

// Result:
// class Range1
//   enumeration(one, two, three) x[E.one] = E.one;
//   enumeration(one, two, three) x[E.two] = E.two;
//   enumeration(one, two, three) x[E.three] = E.three;
// end Range1;
// endResult
