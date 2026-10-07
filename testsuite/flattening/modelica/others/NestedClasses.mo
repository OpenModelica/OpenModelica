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
// [flattening/modelica/others/NestedClasses.mo:10:5-10:23:writable] Warning: Components are deprecated in class.
// [flattening/modelica/others/NestedClasses.mo:14:5-14:23:writable] Warning: Components are deprecated in class.
// [flattening/modelica/others/NestedClasses.mo:17:3-17:19:writable] Warning: Components are deprecated in class.
// [flattening/modelica/others/NestedClasses.mo:18:3-18:19:writable] Warning: Components are deprecated in class.
// [flattening/modelica/others/NestedClasses.mo:19:3-19:12:writable] Warning: Components are deprecated in class.
//
// endResult
