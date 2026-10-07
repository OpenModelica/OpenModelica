// name: TypeEnumeration
// keywords: type
// status: correct
//
// Tests declaring a type from an enumeration
//

type Enum = enumeration(test1,test2,test3);

model TypeEnumeration
  Enum et;
equation
  et = Enum.test3;
end TypeEnumeration;

// Result:
// class TypeEnumeration
//   enumeration(test1, test2, test3) et;
// equation
//   et = Enum.test3;
// end TypeEnumeration;
// endResult
