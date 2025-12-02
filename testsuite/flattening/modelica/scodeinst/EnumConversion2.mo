// name: EnumConversion2
// keywords:
// status: correct

model EnumConversion2
  type E = enumeration(one, two, three);
  type E2 = E;
  E2 e0 = E2(0);
  E2 e1 = E2(1);
  E2 e2 = E2(2);
  E2 e3 = E2(3);
  E2 e4 = E2(4);
end EnumConversion2;

// Result:
// function EnumConversion2.E2 "Automatically generated conversion operator for E2"
//   input Integer index;
//   output enumeration(one, two, three) value;
// algorithm
//   assert(index >= 1 and index <= 3, "Enumeration index '" + String(index, 0, true) + "' out of bounds in call to E2()");
//   value := {E.one, E.two, E.three}[index];
// end EnumConversion2.E2;
//
// class EnumConversion2
//   enumeration(one, two, three) e0 = EnumConversion2.E2(0);
//   enumeration(one, two, three) e1 = E.one;
//   enumeration(one, two, three) e2 = E.two;
//   enumeration(one, two, three) e3 = E.three;
//   enumeration(one, two, three) e4 = EnumConversion2.E2(4);
// end EnumConversion2;
// endResult
