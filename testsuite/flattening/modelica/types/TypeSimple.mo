// name: TypeSimple
// keywords: type
// status: correct
// cflags: -d=-newInst
//
// Tests simple type declaration
//

type MyType = Integer;

model TypeSimple
  MyType mt;
equation
  mt = 2;
end TypeSimple;

// Result:
// class TypeSimple
//   Integer mt;
// equation
//   mt = 2;
// end TypeSimple;
// endResult
