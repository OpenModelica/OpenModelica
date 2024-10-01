// name: Assert1
// keywords:
// status: correct
//

model Assert1
equation
  assert(time > 1, "test");
end Assert1;

// Result:
// class Assert1
// equation
//   assert(time > 1.0, "test");
// end Assert1;
// endResult
