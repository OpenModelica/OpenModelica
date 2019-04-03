// name:     Enum10
// keywords: enumeration enum type extends
// status:   correct
//
// Tests creation of new enumeration type by extending an already existing one.
//

type enum1 = enumeration(one, two, three);
type enum2 = enum1(start = two);

model Enum10
  enum1 e1;
  enum2 e2;
end Enum10;

// Result:
// class Enum10
//   enumeration(one, two, three) e1;
//   enumeration(one, two, three) e2(start = enum1.two);
// end Enum10;
// endResult
