// name: StringInteger
// keywords: string
// status: correct
//
// Tests string conversion from Integer
//

model StringInteger
  String s1;
  String s2;
  Integer i;
  String s3;
equation
  s1 = String(4711);
  s2 = String(1138, minimumLength = 12, leftJustified = false);
  i = 1337;
  s3 = String(i);
end StringInteger;

// Result:
// class StringInteger
//   String s1;
//   String s2;
//   Integer i;
//   String s3;
// equation
//   s1 = "4711";
//   s2 = "        1138";
//   i = 1337;
//   s3 = String(i, 0, true);
// end StringInteger;
// endResult
