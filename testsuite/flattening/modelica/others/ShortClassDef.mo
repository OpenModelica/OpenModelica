// name: ShortClassDef
// keywords: class
// status: correct
//
// Tests short class definitions of the form class foo = bar;
//

class TestClass
  Integer i1;
end TestClass;

class ShortClassDef = TestClass annotation(__OpenModelica_commandLineOptions="-d=-newInst");

// Result:
// class ShortClassDef
//   Integer i1;
// end ShortClassDef;
// endResult
