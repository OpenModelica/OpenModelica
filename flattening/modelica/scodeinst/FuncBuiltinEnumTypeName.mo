// name: FuncBuiltinEnumTypeName
// keywords: enumeration
// status: correct
// cflags: -d=newInst
//
// Tests that enumeration type names can be used to convert an Integer to an
// enumeration value.
//

model FuncBuiltinEnumTypeName
  type E = enumeration(one, two, three);
  E e = E(2);
end FuncBuiltinEnumTypeName;

// Result:
// class FuncBuiltinEnumTypeName
//   enumeration(one, two, three) e = E.two;
// end FuncBuiltinEnumTypeName;
// endResult
