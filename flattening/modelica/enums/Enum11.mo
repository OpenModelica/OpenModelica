// name:     Enum11
// keywords: enumeration enum
// status:   correct
//
// Tests integer conversion of enumeration types.
//

model Enum11

type MyEnum=enumeration(A,B,C);

MyEnum A=MyEnum.A;

Integer i = Integer(A);
end Enum11;
// Result:
// class Enum11
//   enumeration(A, B, C) A = Enum11.MyEnum.A;
//   Integer i = Integer(A);
// end Enum11;
// endResult
