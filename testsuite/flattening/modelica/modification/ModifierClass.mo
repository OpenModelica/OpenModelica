// name: ModifierClass
// keywords: modifier
// status: correct
//
// Tests modification of short class declarations
//

class ClassA
  parameter Real r1;
end ClassA;

class ModifierClass = ClassA(r1 = 4711.0);

// Result:
// class ModifierClass
//   parameter Real r1 = 4711.0;
// end ModifierClass;
// [flattening/modelica/modification/ModifierClass.mo:9:3-9:20:writable] Warning: Components are deprecated in class.
//
// endResult
