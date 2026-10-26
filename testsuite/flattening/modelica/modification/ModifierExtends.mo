// name: ModifierExtends
// keywords: modifier
// status: correct
//
// Tests modification of extends clauses
//

class ClassA
  parameter Real r1;
end ClassA;

class ModifierExtends
  extends ClassA(r1 = 4711.0);
end ModifierExtends;

// Result:
// class ModifierExtends
//   parameter Real r1 = 4711.0;
// end ModifierExtends;
// endResult
