// name: CevalIntegerEnum1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalIntegerEnum1
  type E = enumeration(one, two, three);
  constant Integer i1 = Integer(E.one);
  constant Integer i2 = Integer(E.two);
  constant Integer i3 = Integer(E.three);
end CevalIntegerEnum1;

// Result:
// class CevalIntegerEnum1
//   constant Integer i1 = 1;
//   constant Integer i2 = 2;
//   constant Integer i3 = 3;
// end CevalIntegerEnum1;
// endResult
