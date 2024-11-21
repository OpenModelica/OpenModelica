// name: String1
// status: correct

model String1
  Real r;
  Integer i;
  Boolean b;
  type E = enumeration(one, two, three);
  E e;

  String s_r1 = String(r);
  String s_r2 = String(r, format = "g");
  String s_r3 = String(r, minimumLength = 2, leftJustified = false, significantDigits = 4);
  String s_r4 = String(r, minimumLength = 0, leftJustified = true, significantDigits = 6);
  String s_r5 = String(r, minimumLength = 2, significantDigits = 6);

  String s_i1 = String(i);
  String s_i2 = String(i, format = "d");
  String s_i3 = String(i, minimumLength = 8, leftJustified = false);

  String s_b1 = String(b);
  String s_b2 = String(b, minimumLength = 4, leftJustified = true);

  String s_e1 = String(e);
  String s_e2 = String(e, minimumLength = 12, leftJustified = false);

  annotation(__OpenModelica_commandLineOptions="-f");
end String1;

// Result:
// //! base 0.1.0
// package 'String1'
//   type 'E' = enumeration('one', 'two', 'three');
//
//   model 'String1'
//     Real 'r';
//     Integer 'i';
//     Boolean 'b';
//     'E' 'e';
//     String 's_r1' = String('r');
//     String 's_r2' = String('r', format = "g");
//     String 's_r3' = String('r', significantDigits = 4, minimumLength = 2, leftJustified = false);
//     String 's_r4' = String('r');
//     String 's_r5' = String('r', minimumLength = 2);
//     String 's_i1' = String('i');
//     String 's_i2' = String('i', format = "d");
//     String 's_i3' = String('i', minimumLength = 8, leftJustified = false);
//     String 's_b1' = String('b');
//     String 's_b2' = String('b', minimumLength = 4);
//     String 's_e1' = String('e');
//     String 's_e2' = String('e', minimumLength = 12, leftJustified = false);
//   end 'String1';
// end 'String1';
// endResult
