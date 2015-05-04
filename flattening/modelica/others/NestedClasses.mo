// name: NestedClasses
// keywords: class
// status: correct
//
// Tests nested classes
//

class NestedClasses
  class NestedClass1
    Integer nestedInt1;
  end NestedClass1;

  class NestedClass2
    Integer nestedInt2;
  end NestedClass2;

  NestedClass1 nc1;
  NestedClass2 nc2;
  Integer i;
end NestedClasses;

// Result:
// class NestedClasses
//   Integer nc1.nestedInt1;
//   Integer nc2.nestedInt2;
//   Integer i;
// end NestedClasses;
// endResult
