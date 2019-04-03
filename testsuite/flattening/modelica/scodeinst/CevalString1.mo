// name: CevalString1
// keywords:
// status: correct
// cflags: -d=newInst
//

model CevalString1
  type E = enumeration(one, two, three);

  constant String s1 = String(1235);
  constant String s2 = String(485, minimumLength = 10);
  constant String s3 = String(true);
  constant String s4 = String(false);
  constant String s5 = String(E.two);
  constant String s6 = String(E.three, leftJustified = false, minimumLength = 7);
  constant String s7 = String(234.54);
  constant String s8 = String(945.2, minimumLength = 10);
  constant String s9 = String(0.3412341234123412, format = "%.10g");
  constant String s10 = String(0.3412341234123412, significantDigits = 10);
end CevalString1;

// Result:
// class CevalString1
//   constant String s1 = "1235";
//   constant String s2 = "485       ";
//   constant String s3 = "true";
//   constant String s4 = "false";
//   constant String s5 = "two";
//   constant String s6 = "  three";
//   constant String s7 = "234.54";
//   constant String s8 = "945.2     ";
//   constant String s9 = "0.3412341234";
//   constant String s10 = "0.3412341234";
// end CevalString1;
// endResult
