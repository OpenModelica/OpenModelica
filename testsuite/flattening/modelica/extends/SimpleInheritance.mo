// name: SimpleInheritance
// keywords: class, inheritance
// status: correct
//
// Tests simple inheritance using the extends keyword
//

class C1
  Integer i1;
end C1;

class C2
  extends C1;
  Integer i2;
end C2;

// Result:
// class C2
//   Integer i1;
//   Integer i2;
// end C2;
// [flattening/modelica/extends/SimpleInheritance.mo:14:3-14:13:writable] Warning: Components are deprecated in class.
//
// endResult
