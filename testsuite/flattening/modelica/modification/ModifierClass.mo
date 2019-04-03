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
// endResult
