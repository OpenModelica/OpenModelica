// name: ShortClassDef
// keywords: class
// status: correct
//
// Tests short class definitions of the form class foo = bar;
//

class TestClass
  Integer i1;
end TestClass;

class ShortClassDef = TestClass;

// Result:
// class ShortClassDef
//   Integer i1;
// end ShortClassDef;
// [flattening/modelica/others/ShortClassDef.mo:9:3-9:13:writable] Warning: Components are deprecated in class.
//
// endResult
