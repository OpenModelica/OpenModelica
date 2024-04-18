// name: EnumConversion3
// keywords:
// status: correct
// cflags: -d=newInst

model A
  replaceable type AE = enumeration(:);
  parameter AE ae = AE(1);
end A;

model EnumConversion3
  type E = enumeration(one, two, three);
  A a(redeclare type AE = E);
end EnumConversion3;

// Result:
// class EnumConversion3
//   parameter enumeration(one, two, three) a.ae = E.one;
// end EnumConversion3;
// endResult
