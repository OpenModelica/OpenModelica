// name: FuncString
// keywords:
// status: correct
// cflags: -d=newInst
//
// Tests the builtin String function.
//

model FuncString
  type E = enumeration(one, two, three);

  String s1 = String(1);
  String s2 = String(E.one);
  String s3 = String(true);
  String s4 = String(1.0);
  String s5 = String(1.0, significantDigits = 3);
  String s6 = String(1.0, format = "-0.4g");
  String s7 = String(1, leftJustified = false, minimumLength = 3);
end FuncString;

// Result:
// class FuncString
//   String s1 = "1";
//   String s2 = "one";
//   String s3 = "true";
//   String s4 = "1";
//   String s5 = "1";
//   String s6 = "-0.4g";
//   String s7 = "  1";
// end FuncString;
// endResult
