// name: ShortClassDef
// keywords: class
// status: correct
//
// Tests short class definitions of the form model foo = bar;
//

model TestClass
  Integer i1;
end TestClass;

model ShortClassDef = TestClass;

// Result:
// class ShortClassDef
//   Integer i1;
// end ShortClassDef;
// endResult
