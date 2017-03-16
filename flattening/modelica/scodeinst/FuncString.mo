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
  String s4 = String(1.0, significantDigits = 3);
  String s5 = String(1.0, format = "-0.4g");
  String s6 = String(1, leftJustified = false, minimumLength = 3);
end FuncString;

// Result:
// class FuncString
//   String s1 = String(1, 0, true);
//   String s2 = String(E.one, 0, true);
//   String s3 = String(true, 0, true);
//   String s4 = String(1.0, 3, 0, true);
//   String s5 = String(1.0, "-0.4g");
//   String s6 = String(1, 3, false);
// end FuncString;
// endResult
