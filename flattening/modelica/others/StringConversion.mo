// name: StringConversion
// keywords: string
// status: correct
//
// Tests conversion of strings from other datatypes
//

model StringConversion
  String s1 = String(true);
  String s2 = String(4711, minimumLength = 12, leftJustified = false);
  String s3 = String(3.14159265, significantDigits = 4);
end StringConversion;

// Result:
// class StringConversion
//   String s1 = "true";
//   String s2 = "        4711";
//   String s3 = "3.142";
// end StringConversion;
// endResult
