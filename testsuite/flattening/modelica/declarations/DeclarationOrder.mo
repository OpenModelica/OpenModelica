// name: DeclarationOrder
// keywords: component, declaration
// status: correct
//
// Tests to make sure declaration order does not matter
//

model Test
  C1 testComponent(x = 2);
  Integer x = y;
  constant Integer y = 3;
end Test;

class C1
  parameter Integer x = 1;
end C1;

model DeclarationOrder
  Test t;
end DeclarationOrder;

// Result:
// class DeclarationOrder
//   parameter Integer t.testComponent.x = 2;
//   Integer t.x = 3;
//   constant Integer t.y = 3;
// end DeclarationOrder;
// endResult
