// name: EnumRangeBinding1
// keywords:
// status: correct
// cflags: -d=newInst
//

model EnumRangeBinding1
  type E = enumeration(one, two, three, four);
  E e1[E] = E.one:E.four;
  E e2[2] = E.two:E.three;
end EnumRangeBinding1;

// Result:
// class EnumRangeBinding1
//   enumeration(one, two, three, four) e1[E.one];
//   enumeration(one, two, three, four) e1[E.two];
//   enumeration(one, two, three, four) e1[E.three];
//   enumeration(one, two, three, four) e1[E.four];
//   enumeration(one, two, three, four) e2[1];
//   enumeration(one, two, three, four) e2[2];
// equation
//   e1 = E.one:E.four;
//   e2 = E.two:E.three;
// end EnumRangeBinding1;
// endResult
