// name: StringReal
// keywords: string
// status: correct
//
// Tests conversion to string from Real
//

model StringReal
  String s1;
  String s2;
  Real r;
  String s3;
equation
  s1 = String(111.222);
  s2 = String(3.14159265, significantDigits = 4);
  r = 1234.5678;
  s3 = String(r);
end StringReal;

// Result:
// class StringReal
//   String s1;
//   String s2;
//   Real r;
//   String s3;
// equation
//   s1 = "111.222";
//   s2 = "3.142";
//   r = 1234.5678;
//   s3 = String(r, 6, 0, true);
// end StringReal;
// endResult
