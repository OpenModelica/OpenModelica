// name:     Enumeration8
// keywords: enumeration enum string String
// status:   correct
//
//
//

type Enum = enumeration(test1,test2,test3);

model Enumeration8
  parameter String s = String(Enum.test2);
  Real x;
  String ss;
equation
  der(x) = x;
  ss = String(Enum.test1);
end Enumeration8;


// Result:
// class Enumeration8
//   parameter String s = "test2";
//   Real x;
//   String ss;
// equation
//   der(x) = x;
//   ss = "test1";
// end Enumeration8;
// endResult
