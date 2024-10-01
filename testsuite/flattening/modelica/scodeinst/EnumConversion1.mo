// name: EnumConversion1
// keywords:
// status: correct

model EnumConversion1
  type E = enumeration(one, two, three);
  E e0 = E(0);
  E e1 = E(1);
  E e2 = E(2);
  E e3 = E(3);
  E e4 = E(4);
end EnumConversion1;

// Result:
// function EnumConversion1.E "Automatically generated conversion operator for E"
//   input Integer index;
//   output enumeration(one, two, three) value;
// algorithm
//   assert(index >= 1 and index <= 3, "Enumeration index '" + String(index, 0, true) + "' out of bounds in call to E()");
//   value := {E.one, E.two, E.three}[index];
// end EnumConversion1.E;
//
// class EnumConversion1
//   enumeration(one, two, three) e0 = EnumConversion1.E(0);
//   enumeration(one, two, three) e1 = E.one;
//   enumeration(one, two, three) e2 = E.two;
//   enumeration(one, two, three) e3 = E.three;
//   enumeration(one, two, three) e4 = EnumConversion1.E(4);
// end EnumConversion1;
// endResult
