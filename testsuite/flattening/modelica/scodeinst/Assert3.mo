// name: Assert3
// keywords:
// status: correct
//

model Assert3
equation
  assert(time > 2, "message", AssertionLevel.warning);
end Assert3;

// Result:
// class Assert3
// equation
//   assert(time > 2.0, "message", AssertionLevel.warning);
// end Assert3;
// endResult
