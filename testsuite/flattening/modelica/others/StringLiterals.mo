// name: StringLiterals
// keywords: string
// status: correct

model StringLiterals
  // Skipping \r since it's weird :)
  constant String s = "\'\"\?\\\a\b\f\n\t\v";
  String str;
  Boolean eq = "ab\n" == "ab
";
equation
  str = "test";
end StringLiterals;

// Result:
// class StringLiterals
//   constant String s = "'\"?\\\a\b\f
//   \v";
//   String str;
//   Boolean eq = true;
// equation
//   str = "test";
// end StringLiterals;
// endResult
