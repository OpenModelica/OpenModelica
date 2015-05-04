// name: StringBoolean
// keywords: string
// status: correct
//
// Tests string conversion from boolean
//

model StringBoolean
  String s1;
  String s2;
  Boolean b;
  String s3;
equation
  s1 = String(true);
  s2 = String(false);
  b = true;
  s3 = String(b);
end StringBoolean;

// Result:
// class StringBoolean
//   String s1;
//   String s2;
//   Boolean b;
//   String s3;
// equation
//   s1 = "true";
//   s2 = "false";
//   b = true;
//   s3 = String(b, 0, true);
// end StringBoolean;
// endResult
