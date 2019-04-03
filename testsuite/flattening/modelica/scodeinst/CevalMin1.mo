// name: CevalMin1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalMin1
  constant Real r1 = 1.0;
  constant Real r2 = 2.0;
  constant Real r3 = min(r1, r2);
  constant Integer i1 = 2;
  constant Integer i2 = 1;
  constant Integer i3 = min(i1, i2);
  constant Boolean b1 = true;
  constant Boolean b2 = false;
  constant Boolean b3 = min(b1, b2);
  type E = enumeration(one, two, three, four);
  constant E e1 = E.two;
  constant E e2 = E.four;
  constant E e3 = min(e2, e1);
end CevalMin1;

// Result:
// class CevalMin1
//   constant Real r1 = 1.0;
//   constant Real r2 = 2.0;
//   constant Real r3 = 1.0;
//   constant Integer i1 = 2;
//   constant Integer i2 = 1;
//   constant Integer i3 = 1;
//   constant Boolean b1 = true;
//   constant Boolean b2 = false;
//   constant Boolean b3 = false;
//   constant enumeration(one, two, three, four) e1 = E.two;
//   constant enumeration(one, two, three, four) e2 = E.four;
//   constant enumeration(one, two, three, four) e3 = E.two;
// end CevalMin1;
// endResult
