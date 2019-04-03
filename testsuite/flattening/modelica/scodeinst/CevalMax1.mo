// name: CevalMax1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalMax1
  constant Real r1 = 1.0;
  constant Real r2 = 2.0;
  constant Real r3 = max(r1, r2);
  constant Integer i1 = 2;
  constant Integer i2 = 1;
  constant Integer i3 = max(i1, i2);
  constant Boolean b1 = true;
  constant Boolean b2 = false;
  constant Boolean b3 = max(b1, b2);
  type E = enumeration(one, two, three, four);
  constant E e1 = E.two;
  constant E e2 = E.four;
  constant E e3 = max(e2, e1);
end CevalMax1;

// Result:
// class CevalMax1
//   constant Real r1 = 1.0;
//   constant Real r2 = 2.0;
//   constant Real r3 = 2.0;
//   constant Integer i1 = 2;
//   constant Integer i2 = 1;
//   constant Integer i3 = 2;
//   constant Boolean b1 = true;
//   constant Boolean b2 = false;
//   constant Boolean b3 = true;
//   constant enumeration(one, two, three, four) e1 = E.two;
//   constant enumeration(one, two, three, four) e2 = E.four;
//   constant enumeration(one, two, three, four) e3 = E.four;
// end CevalMax1;
// endResult
